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
require_relative '../lib/cisco_node_utils/plb_device_group_node'

include Cisco
# TestInterface - Minitest for general functionality
# of the PlbDeviceGroup class.
class TestPlbDevGrpNode < CiscoTestCase
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
    plbdg1 = PlbDeviceGroup.new('abc')
    n1 = PlbDeviceGroupNode.new(plbdg1.name, '1.1.1.1', 'ip')
    n2 = PlbDeviceGroupNode.new(plbdg1.name, '2.2.2.2', 'ip')
    n3 = PlbDeviceGroupNode.new(plbdg1.name, '3.3.3.3', 'ip')
    assert_includes(PlbDeviceGroupNode.plb_nodes['abc'], '1.1.1.1')
    assert_includes(PlbDeviceGroupNode.plb_nodes['abc'], '2.2.2.2')
    assert_includes(PlbDeviceGroupNode.plb_nodes['abc'], '3.3.3.3')
    plbdg2 = PlbDeviceGroup.new('xyz')
    n4 = PlbDeviceGroupNode.new(plbdg2.name, '2000::1', 'IPv6')
    assert_includes(PlbDeviceGroupNode.plb_nodes['xyz'], '2000::1')
    plbdg3 = PlbDeviceGroup.new('efg')
    n5 = PlbDeviceGroupNode.new(plbdg3.name, '1.1.1.1', 'ip')
    assert_includes(PlbDeviceGroupNode.plb_nodes['efg'], '1.1.1.1')

    n1.destroy
    refute_includes(PlbDeviceGroupNode.plb_nodes['abc'], '1.1.1.1')
    n2.destroy
    n3.destroy
    assert_empty(PlbDeviceGroupNode.plb_nodes['abc'])
    n4.destroy
    assert_empty(PlbDeviceGroupNode.plb_nodes['xyz'])
    n5.destroy
    assert_empty(PlbDeviceGroupNode.plb_nodes['efg'])
  end

  def probe_helper(props)
    test_hash = {
      probe_frequency:  9,
      probe_retry_down: 5,
      probe_retry_up:   5,
      probe_timeout:    6,
    }.merge!(props)

    PlbDeviceGroup.new('new_group')
    idg = PlbDeviceGroupNode.new('new_group', '1.1.1.1', 'ip')
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

  def test_hot_standby_weight
    plbdg = PlbDeviceGroup.new('new_group')
    idg = PlbDeviceGroupNode.new('new_group', '1.1.1.1', 'ip')
    hot_standby = true
    weight = idg.default_weight
    idg.hs_weight(hot_standby, weight)
    assert_equal(true, idg.hot_standby)
    assert_equal(idg.default_weight,
                 idg.weight)
    hot_standby = idg.default_hot_standby
    weight = idg.default_weight
    idg.hs_weight(hot_standby, weight)
    assert_equal(idg.default_hot_standby, idg.hot_standby)
    assert_equal(idg.default_weight,
                 idg.weight)
    hot_standby = idg.default_hot_standby
    weight = 150
    idg.hs_weight(hot_standby, weight)
    assert_equal(idg.default_hot_standby, idg.hot_standby)
    assert_equal(150, idg.weight)
    hot_standby = idg.default_hot_standby
    weight = 200
    idg.hs_weight(hot_standby, weight)
    assert_equal(idg.default_hot_standby, idg.hot_standby)
    assert_equal(200, idg.weight)
    hot_standby = true
    weight = idg.default_weight
    idg.hs_weight(hot_standby, weight)
    assert_equal(true, idg.hot_standby)
    assert_equal(idg.default_weight,
                 idg.weight)
    hot_standby = idg.default_hot_standby
    weight = 200
    idg.hs_weight(hot_standby, weight)
    assert_equal(idg.default_hot_standby, idg.hot_standby)
    assert_equal(200, idg.weight)
    idg.destroy
    plbdg.destroy
  end
end
