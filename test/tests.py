"""
Integration tests for autopilotpattern/nginx. These tests are executed
inside a test-running container based on autopilotpattern/testing.
"""
from collections import defaultdict
import os
from os.path import expanduser
import random
import re
import string
import subprocess
import sys
import time
import unittest
import uuid

from testcases import AutopilotPatternTest, WaitTimeoutError, \
     dump_environment_to_file
import requests
from IPy import IP


class NginxStackTest(AutopilotPatternTest):

    compose_file = 'triton/docker-compose.yml'
    project_name = 'nginx'

    def setUp(self):
        """
        autopilotpattern/nginx setup.sh creates environment values to use
        as part of a CNS entry for Consul. We use these values to construct
        a CNS entry for this test rig as well.
        """
        account = os.environ['TRITON_ACCOUNT']
        dc = os.environ['TRITON_DC']
        self.consul_cns = 'consul.svc.{}.{}.triton.zone'.format(account, dc)
        self.nginx_cns = 'nginx-frontend.svc.{}.{}.triton.zone'.format(account, dc)
        os.environ['CONSUL'] = self.consul_cns

    def test_scaleup_and_down(self):

        self.instrument(self.wait_for_containers,
                        {'backend': 1, "nginx": 1, "consul": 1}, timeout=300)
        self.instrument(self.wait_for_service, 'backend', count=1, timeout=120)
        self.instrument(self.wait_for_service, 'containerpilot', count=1, timeout=120)
        self.instrument(self.wait_for_service, 'nginx', count=1, timeout=120)
        self.instrument(self.wait_for_service, 'nginx-public', count=1, timeout=120)
        # self.wait_for_service('nginx-public-ssl', count=1) # TODO
        self.instrument(self.wait_for_cns)

        self.compose_scale('backend', 2)
        self.instrument(self.wait_for_containers,
                        {'backend': 2, "nginx": 1, "consul": 1}, timeout=300)
        self.instrument(self.wait_for_service, 'backend', count=2, timeout=60)

        # get our expected IP addresses
        _, backend1_ip = self.get_ips('backend_1')
        _, backend2_ip = self.get_ips('backend_2')

        # make sure nginx has both of them
        self.compare_backends([backend1_ip, backend2_ip])

        # netsplit a backend and make sure nginx converges
        self.docker_exec('backend_2', 'ifconfig eth0 down')
        self.instrument(self.wait_for_service, 'backend', count=1)
        self.compare_backends([backend1_ip])

        # heal netsplit and make sure nginx converges
        self.docker_exec('backend_2', 'ifconfig eth0 up')
        self.instrument(self.wait_for_service, 'backend', count=2, timeout=60)
        self.compare_backends([backend1_ip, backend2_ip])

    def wait_for_containers(self, expected={}, timeout=30):
        """
        Waits for all containers to be marked as 'Up' for all services.
        `expected` should be a dict of {"service_name": count}.
        TODO: lower this into the base class implementation.
        """
        svc_regex = re.compile(r'^{}_(\w+)_\d+$'.format(self.project_name))

        def get_service_name(container_name):
            return svc_regex.match(container_name).group(1)

        while timeout > 0:
            containers = self.compose_ps()
            found = defaultdict(int)
            states = []
            for container in containers:
                service = get_service_name(container.name)
                found[service] = found[service] + 1
                states.append(container.state == 'Up')
            if all(states):
                if not expected or found == expected:
                    break
            time.sleep(1)
            timeout -= 1
        else:
            raise WaitTimeoutError("Timed out waiting for containers to start.")


    def wait_for_cns(self, timeout=60):
        """ wait for CNS to catch up """
        while timeout > 0:
            try:
                r = requests.get('http://{}'.format(self.nginx_cns)) # TODO: SSL
                if r.status_code == 200:
                    break
            except requests.exceptions.ConnectionError:
                timeout -= 1
                time.sleep(1)
        else:
            self.fail("nginx has not become reachable at {}"
                      .format(self.nginx_cns))

    def get_possible_backend_ips(self, timeout=60):
        _, ips = self.get_service_ips('backend')
        ips.sort()
        return ips

    def compare_backends(self, expected, timeout=60):
        expected.sort()
        patt = 'server \d{2,3}\.\d{2,3}\.\d{2,3}\.\d{2,3}\:3001;'
        while timeout > 0:
            conf = self.docker_exec('nginx_1',
                                    'cat /etc/nginx/conf.d/site.conf')
            actual = re.findall(patt, conf)
            actual = [IP(a.replace('server', '').replace(':3001;', '').strip())
                      for a in actual]
            actual.sort()
            if actual == expected:
                break

            timeout -= 1
            time.sleep(1)
        else:
            self.fail("expected {} but got {} for Nginx backends"
                      .format(expected, actual))


if __name__ == "__main__":
    unittest.main()
