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
        self.compare_backends()

        # netsplit a backend
        self.docker_exec('backend_2', 'ifconfig eth0 down')
        self.instrument(self.wait_for_service, 'backend', count=1)
        self.compare_backends()

        # heal netsplit
        self.docker_exec('backend_2', 'ifconfig eth0 up')
        self.instrument(self.wait_for_service, 'backend', count=2, timeout=60)
        self.compare_backends()

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
                pass
            timeout -= 1
            time.sleep(1)
        else:
            self.fail("nginx has not become reachable at {}"
                      .format(self.nginx_cns))


    def compare_backends(self):
        expected = self.get_service_instances_from_consul('backend').sort()
        actual = list(set([self.query_for_backend() for _ in range(10)])).sort()
        self.assertEqual(expected, actual,
                         'Expected {} but got {} for Nginx backends'
                         .format(expected, actual))

    def query_for_backend(self):
        r = requests.get('http://{}'.format(self.nginx_cns)) # TODO: SSL
        if r.status_code != 200:
            self.fail('Expected 200 OK but got {}'.format(r.status_code))
        return r.text.strip('HelloWorld\n ')




if __name__ == "__main__":
    unittest.main()
