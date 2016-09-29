# Copyright (c) 2016 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/plb_device_group'

include Cisco
# TestInterface - Minitest for general functionality
# of the PlbDeviceGroup class.
class TestPlbDevGrp < CiscoTestCase
  @skip_unless_supported = 'plb_device_group'
  # Tests

  def setup
    super
    config 'no feature plb'
  end

  def teardown
    config 'no feature plb'
    super
  end

  def test_create_destroy
    i1 = PlbDeviceGroup.new('abc')
    i2 = PlbDeviceGroup.new('BCD')
    i3 = PlbDeviceGroup.new('xyzABC')
    assert_equal(3, PlbDeviceGroup.plbs.keys.count)

    i2.destroy
    assert_equal(2, PlbDeviceGroup.plbs.keys.count)

    i1.destroy
    i3.destroy
    assert_equal(0, PlbDeviceGroup.plbs.keys.count)
  end

  def probe_helper(props)
    test_hash = {
      probe_frequency:  9,
      probe_retry_down: 5,
      probe_retry_up:   5,
      probe_timeout:    6,
    }.merge!(props)

    idg = PlbDeviceGroup.new('new_group')
    idg.probe_set(test_hash)
    idg
  end

  def test_probe_icmp
    idg = probe_helper(probe_type: 'icmp')
    assert_equal('icmp', idg.probe_type)
    assert_equal(9, idg.probe_frequency)
    assert_equal(6, idg.probe_timeout)
    assert_equal(5, idg.probe_retry_up)
    assert_equal(5, idg.probe_retry_down)
    idg = probe_helper(probe_type:       'icmp',
                       probe_frequency:  idg.default_probe_frequency,
                       probe_retry_up:   idg.default_probe_retry_up,
                       probe_retry_down: idg.default_probe_retry_down,
                       probe_timeout:    idg.default_probe_timeout)
    assert_equal(idg.default_probe_frequency, idg.probe_frequency)
    assert_equal(idg.default_probe_timeout, idg.probe_timeout)
    assert_equal(idg.default_probe_retry_up, idg.probe_retry_up)
    assert_equal(idg.default_probe_retry_down, idg.probe_retry_down)
    idg = probe_helper(probe_type: idg.default_probe_type)
    assert_equal(idg.default_probe_type, idg.probe_type)
    idg.destroy
  end

  def test_probe_dns
    host = 'resolver1.opendns.com'
    idg = probe_helper(probe_type: 'dns', probe_dns_host: host)
    assert_equal('dns', idg.probe_type)
    assert_equal(host, idg.probe_dns_host)
    assert_equal(9, idg.probe_frequency)
    assert_equal(6, idg.probe_timeout)
    assert_equal(5, idg.probe_retry_up)
    assert_equal(5, idg.probe_retry_down)
    host = '208.67.220.222'
    idg = probe_helper(probe_type: 'dns', probe_dns_host: host,
            probe_frequency: idg.default_probe_frequency,
            probe_retry_up: idg.default_probe_retry_up,
            probe_retry_down: idg.default_probe_retry_down,
            probe_timeout: idg.default_probe_timeout)
    assert_equal(host, idg.probe_dns_host)
    assert_equal(idg.default_probe_frequency, idg.probe_frequency)
    assert_equal(idg.default_probe_timeout, idg.probe_timeout)
    assert_equal(idg.default_probe_retry_up, idg.probe_retry_up)
    assert_equal(idg.default_probe_retry_down, idg.probe_retry_down)
    host = '2620:0:ccd::2'
    idg = probe_helper(probe_type: 'dns', probe_dns_host: host,
            probe_frequency: idg.default_probe_frequency,
            probe_retry_up: idg.default_probe_retry_up,
            probe_retry_down: idg.default_probe_retry_down,
            probe_timeout: idg.default_probe_timeout)
    assert_equal(host, idg.probe_dns_host)
    idg.destroy
  end

  def test_probe_tcp_udp
    port = 11_111
    type = 'tcp'
    idg = probe_helper(probe_type: type, probe_port: port,
                      probe_control: true)
    assert_equal(type, idg.probe_type)
    assert_equal(port, idg.probe_port)
    assert_equal(true, idg.probe_control)
    assert_equal(9, idg.probe_frequency)
    assert_equal(6, idg.probe_timeout)
    assert_equal(5, idg.probe_retry_up)
    assert_equal(5, idg.probe_retry_down)
    type = 'udp'
    idg = probe_helper(probe_type: type, probe_port: port,
            probe_control: idg.default_probe_control,
            probe_frequency: idg.default_probe_frequency,
            probe_retry_up: idg.default_probe_retry_up,
            probe_retry_down: idg.default_probe_retry_down,
            probe_timeout: idg.default_probe_timeout)
    assert_equal(type, idg.probe_type)
    assert_equal(port, idg.probe_port)
    assert_equal(idg.default_probe_control, idg.probe_control)
    assert_equal(idg.default_probe_frequency, idg.probe_frequency)
    assert_equal(idg.default_probe_timeout, idg.probe_timeout)
    assert_equal(idg.default_probe_retry_up, idg.probe_retry_up)
    assert_equal(idg.default_probe_retry_down, idg.probe_retry_down)
    idg.destroy
  end
end
