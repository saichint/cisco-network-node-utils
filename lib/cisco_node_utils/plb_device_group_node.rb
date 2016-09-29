# February 2016, Sai Chintalapudi
#
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

require_relative 'node_util'
require_relative 'plb_device_group'

module Cisco
  # node_utils class for plb_device_group_node
  class PlbDeviceGroupNode < PlbDeviceGroup
    attr_reader :plb_device_group_name, :name, :node_type

    def initialize(plb_dg_name, node_name, node_type, instantiate=true)
      fail TypeError unless plb_dg_name.is_a?(String)
      fail TypeError unless node_name.is_a?(String)
      fail ArgumentError unless plb_dg_name.length > 0
      fail ArgumentError unless node_name.length > 0

      @plb_device_group_name = plb_dg_name
      @plbdg = PlbDeviceGroup.plbs[plb_dg_name]
      fail "plb device-group #{plb_dg_name} does not exist" if
      @plbdg.nil?
      @name = node_name
      @node_type = node_type

      set_args_keys_default
      create_node if instantiate
    end

    # plb_device_group_nodes have the name form as
    # node ip 1.1.1.1
    # node IPv6 2000::1
    # and they depdend on the device_group
    def self.plb_nodes(node_name=nil)
      fail TypeError unless node_name.is_a?(String) || node_name.nil?
      plb_nodes = {}
      plb_list = PlbDeviceGroup.plbs
      return plb_nodes if plb_list.nil?
      plb_list.keys.each do |name|
        plb_nodes[name] = {}
        match = config_get('plb_device_group',
                           'all_plb_device_group_nodes', name: name)
        next if match.nil?
        match.each do |vars|
          ntype = vars[0]
          nname = vars[1].strip
          next unless node_name.nil? || nname == node_name
          plb_nodes[name][nname] =
              PlbDeviceGroupNode.new(name, nname, ntype, false)
        end
      end
      plb_nodes
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def ==(other)
      (plb_device_group_name == other.plb_device_group_name) &&
        (name == other.name) && (node_type == other.node_type)
    end

    def create_node
      config_set('plb_device_group', 'create_node',
                 name: @plbdg.name, ntype: @node_type, nname: @name)
    end

    def destroy
      config_set('plb_device_group', 'destroy_node', name: @plbdg.name,
                ntype: @node_type, nname: @name)
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = { name: @plbdg.name }
      @set_args[:ntype] = @node_type
      @set_args[:nname] = @name
      @get_args = @set_args
    end

    def hot_standby
      config_get('plb_device_group', 'hot_standby', @get_args)
    end

    # DO NOT call this directly
    def lhot_standby=(state)
      no_cmd = (state ? '' : 'no')
      @set_args[:state] = no_cmd
      config_set('plb_device_group', 'hot_standby', @set_args)
      set_args_keys_default
    end

    def default_hot_standby
      config_get_default('plb_device_group', 'hot_standby')
    end

    def weight
      config_get('plb_device_group', 'weight', @get_args)
    end

    # DO NOT call this directly
    def lweight=(val)
      @set_args[:state] = val == default_weight ? 'no' : ''
      @set_args[:weight] = val
      config_set('plb_device_group', 'weight', @set_args)
    end

    # Call this for setting hot_standby and weight together because
    # the CLI is pretty weird and it accepts these params in a very
    # particular way and they cannot even be reset unless proper
    # order is followed
    def hs_weight(hs, wt)
      if hs != hot_standby && hot_standby == default_hot_standby
        self.lweight = wt unless weight == wt
        self.lhot_standby = hs
      elsif hs != hot_standby && hot_standby != default_hot_standby
        self.lhot_standby = hs
        self.lweight = wt unless weight == wt
      elsif wt != weight && weight == default_weight
        self.lweight = wt
      elsif wt != weight && weight != default_weight
        self.lweight = wt
      end
      set_args_keys_default
    end

    def default_weight
      config_get_default('plb_device_group', 'weight')
    end
  end  # Class
end    # Module
