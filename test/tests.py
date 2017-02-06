"""
Integration tests for autopilotpattern/nginx. These tests are executed
inside a test-running container based on autopilotpattern/testing.
"""
import os
from os.path import expanduser
import random
import subprocess
import string
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

    def test_scaleup(self):

        self.wait_for_containers(timeout=300)
        self.wait_for_service('backend', count=1, timeout=60)
        self.wait_for_service('containerpilot', count=1, timeout=60)
        self.wait_for_service('nginx', count=1, timeout=60)
        self.wait_for_service('nginx-public', count=1, timeout=60)
        # self.wait_for_service('nginx-public-ssl', count=1) # TODO

        self.compose_scale('backend', 2)
        self.wait_for_service('backend', count=2)

        expected = self.get_service_instances_from_consul('backend').sort()

        def query_for_backend(self):
            r = requests.get('http://{}'.format(self.nginx_cns)) # TODO: SSL
            if r.status_code != 200:
                self.fail('Expected 200 OK but got {}'.format(r.status_code))
            return r.text.strip('HelloWorld\n ')

        actual = list(set([query_for_backend(self) for _ in range(10)])).sort()

        self.assertEqual(expected, actual,
                         'Expected {} but got {} for Nginx backends'
                         .format(expected, actual))


if __name__ == "__main__":
    unittest.main()
