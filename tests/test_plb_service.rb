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
require_relative '../lib/cisco_node_utils/plb_service'

include Cisco
# TestInterface - Minitest for general functionality
# of the PlbService class.
class TestPlbSvc < CiscoTestCase
  @skip_unless_supported = 'plb_service'
  # Tests

  def setup
    super
    config 'no feature plb'
  end

  def teardown
    config 'no feature plb'
    super
  end

  def test_plb_service_create_destroy
    i1 = PlbService.new('abc')
    i2 = PlbService.new('BCD')
    i3 = PlbService.new('xyzABC')
    assert_equal(3, PlbService.plbs.keys.count)

    i2.destroy
    assert_equal(2, PlbService.plbs.keys.count)

    i1.destroy
    i3.destroy
    assert_equal(0, PlbService.plbs.keys.count)
  end

  def test_access_list
    plb = PlbService.new('new_group')
    config 'ip access-list include'
    config 'ip access-list exclude'
    plb.access_list = 'include'
    plb.exclude_access_list = 'exclude'
    assert_equal('include', plb.access_list)
    assert_equal('exclude', plb.exclude_access_list)
    plb.access_list = plb.default_access_list
    plb.exclude_access_list = plb.default_exclude_access_list
    assert_equal(plb.default_access_list,
                 plb.access_list)
    assert_equal(plb.default_exclude_access_list,
                 plb.exclude_access_list)
    config 'no ip access-list include'
    config 'no ip access-list exclude'
  end

  def test_device_group
    plb = PlbService.new('new_group')
    PlbDeviceGroup.new('myGroup')
    plb.device_group = 'myGroup'
    assert_equal('myGroup', plb.device_group)
    plb.device_group = plb.default_device_group
    assert_equal(plb.default_device_group,
                 plb.device_group)
  end

  def test_fail_action
    plb = PlbService.new('new_group')
    plb.fail_action = true
    assert_equal(true, plb.fail_action)
    plb.fail_action = plb.default_fail_action
    assert_equal(plb.default_fail_action,
                 plb.fail_action)
  end

  def test_ingress_interface
    config 'feature interface-vlan'
    config 'vlan 2'
    config 'interface vlan 2'
    config 'interface port-channel 100 ; no switchport'
    plb = PlbService.new('new_group')
    new_intf = Interface.new(interfaces[0])
    new_intf.switchport_mode = :disabled
    ii = [['vlan2', '1.1.1.1'],
          [interfaces[0], '2.2.2.2'],
          ['port-channel100', '4.4.4.4']]
    plb.ingress_interface = ii
    assert_equal(plb.ingress_interface, ii)
    plb.ingress_interface = plb.default_ingress_interface
    assert_equal(plb.ingress_interface, plb.default_ingress_interface)
    config 'no interface port-channel 100'
    config 'no interface vlan 2'
    config 'no vlan 2'
    config 'no feature interface-vlan'
  end

  def lb_helper(props)
    plb = PlbService.new('new_group')
    test_hash = {
      load_bal_enable:               true,
      load_bal_method_bundle_select: plb.default_load_bal_method_bundle_select,
      load_bal_method_bundle_hash:   plb.default_load_bal_method_bundle_hash,
      load_bal_method_proto:         plb.default_load_bal_method_proto,
      load_bal_buckets:              plb.default_load_bal_buckets,
      load_bal_method_end_port:      plb.default_load_bal_method_end_port,
      load_bal_method_start_port:    plb.default_load_bal_method_start_port,
    }.merge!(props)
    plb.load_balance_set(test_hash)
    plb
  end

  def test_load_balance
    plb = lb_helper(load_bal_method_bundle_select: 'src',
                    load_bal_method_bundle_hash:   'ip',
                    load_bal_buckets:              16,
                    load_bal_mask_pos:             4)
    assert_equal(true, plb.load_bal_enable)
    assert_equal(16, plb.load_bal_buckets)
    assert_equal(4, plb.load_bal_mask_pos)
    assert_equal('ip', plb.load_bal_method_bundle_hash)
    assert_equal('src', plb.load_bal_method_bundle_select)
    plb = lb_helper(load_bal_enable:               true,
                    load_bal_method_bundle_select: 'dst',
                    load_bal_method_bundle_hash:   'ip-l4port',
                    load_bal_buckets:              128,
                    load_bal_mask_pos:             10,
                    load_bal_method_end_port:      700,
                    load_bal_method_proto:         'tcp',
                    load_bal_method_start_port:    200)
    assert_equal(128, plb.load_bal_buckets)
    assert_equal(10, plb.load_bal_mask_pos)
    assert_equal('ip-l4port', plb.load_bal_method_bundle_hash)
    assert_equal('dst', plb.load_bal_method_bundle_select)
    assert_equal(700, plb.load_bal_method_end_port)
    assert_equal(200, plb.load_bal_method_start_port)
    assert_equal('tcp', plb.load_bal_method_proto)
    plb = lb_helper(load_bal_mask_pos: 20)
    assert_equal(plb.default_load_bal_buckets,
                 plb.load_bal_buckets)
    assert_equal(20, plb.load_bal_mask_pos)
    assert_equal(plb.default_load_bal_method_bundle_hash,
                 plb.load_bal_method_bundle_hash)
    assert_equal(plb.default_load_bal_method_bundle_select,
                 plb.load_bal_method_bundle_select)
    assert_equal(plb.default_load_bal_method_end_port,
                 plb.load_bal_method_end_port)
    assert_equal(plb.default_load_bal_method_start_port,
                 plb.load_bal_method_start_port)
    assert_equal(plb.default_load_bal_method_proto,
                 plb.load_bal_method_proto)
    plb = lb_helper(load_bal_enable:  true,
                    load_bal_buckets: 256)
    assert_equal(256, plb.load_bal_buckets)
    assert_equal(plb.default_load_bal_mask_pos,
                 plb.load_bal_mask_pos)
    assert_equal(plb.default_load_bal_method_bundle_hash,
                 plb.load_bal_method_bundle_hash)
    assert_equal(plb.default_load_bal_method_bundle_select,
                 plb.load_bal_method_bundle_select)
    assert_equal(plb.default_load_bal_method_end_port,
                 plb.load_bal_method_end_port)
    assert_equal(plb.default_load_bal_method_start_port,
                 plb.load_bal_method_start_port)
    assert_equal(plb.default_load_bal_method_proto,
                 plb.load_bal_method_proto)
    plb = lb_helper(load_bal_enable: false)
    assert_equal(plb.load_bal_enable,
                 plb.default_load_bal_enable)
    assert_equal(plb.load_bal_buckets, plb.default_load_bal_buckets)
    assert_equal(plb.load_bal_mask_pos, plb.default_load_bal_mask_pos)
    assert_equal(plb.load_bal_method_bundle_hash,
                 plb.default_load_bal_method_bundle_hash)
    assert_equal(plb.load_bal_method_bundle_select,
                 plb.default_load_bal_method_bundle_select)
    assert_equal(plb.load_bal_method_end_port,
                 plb.default_load_bal_method_end_port)
    assert_equal(plb.load_bal_method_start_port,
                 plb.default_load_bal_method_start_port)
    assert_equal(plb.load_bal_method_proto,
                 plb.default_load_bal_method_proto)
  end

  def test_nat_destination
    plb = PlbService.new('new_group')
    if validate_property_excluded?('plb_service', 'nat_destination')
      assert_nil(plb.nat_destination)
      assert_raises(Cisco::UnsupportedError) do
        plb.nat_destination = false
      end
      return
    end
    plbdg = PlbDeviceGroup.new('abc')
    PlbDeviceGroupNode.new(plbdg.name, '1.1.1.1', 'ip')
    plb.device_group = 'abc'
    plb.virtual_ip = ['ip 2.2.2.2 255.255.255.0']
    intf = interfaces[0].dup
    new_intf = Interface.new(interfaces[0])
    new_intf.switchport_mode = :disabled
    ii = [[intf.insert(8, ' '), '2.2.2.2']]
    plb.ingress_interface = ii
    plb.nat_destination = true
    assert_equal(true, plb.nat_destination)
    plb.nat_destination = plb.default_nat_destination
    assert_equal(plb.default_nat_destination, plb.nat_destination)
  end

  def test_shutdown
    plb = PlbService.new('new_group')
    plbdg = PlbDeviceGroup.new('abc')
    PlbDeviceGroupNode.new(plbdg.name, '1.1.1.1', 'ip')
    plb.device_group = 'abc'
    plb.virtual_ip = ['ip 2.2.2.2 255.255.255.0']
    intf = Interface.new(interfaces[0])
    new_intf = Interface.new(interfaces[0])
    new_intf.switchport_mode = :disabled
    intf.switchport_mode = :disabled
    intf_dup = interfaces[0].dup
    ii = [[intf_dup.insert(8, ' '), '2.2.2.2']]
    plb.ingress_interface = ii
    plb.shutdown = false
    assert_equal(false, plb.shutdown)
    plb.shutdown = plb.default_shutdown
    assert_equal(plb.default_shutdown,
                 plb.shutdown)
  end

  def test_peer_local
    plb = PlbService.new('new_group')
    service = 'ser1'
    if validate_property_excluded?('plb_service', 'peer_local')
      assert_nil(plb.peer_local)
      assert_raises(Cisco::UnsupportedError) do
        plb.peer_local = service
      end
      return
    end
    plb.peer_local = service
    assert_equal(service, plb.peer_local)
    plb.peer_local = plb.default_peer_local
    assert_equal(plb.default_peer_local,
                 plb.peer_local)
  end

  def test_virtual_ip
    plb = PlbService.new('new_group')
    PlbDeviceGroup.new('myGroup1')
    PlbDeviceGroup.new('myGroup2')
    values = ['ip 1.1.1.1 255.255.255.0 tcp 2000 advertise enable',
              'ip 2.2.2.2 255.0.0.0 udp 1000 device-group myGroup1',
              'ip 3.3.3.3 255.0.255.0 device-group myGroup2']
    plb.virtual_ip = values
    assert_equal(plb.virtual_ip,
                 values)
    plb.virtual_ip = plb.default_virtual_ip
    assert_equal(plb.virtual_ip,
                 plb.default_virtual_ip)
  end
end
