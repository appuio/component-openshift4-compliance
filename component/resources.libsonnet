// main template for openshift4-compliance
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';

local inv = kap.inventory();
local params = inv.parameters.openshift4_compliance;

local global_name = 'openshift4-monitoring-rules';
local global_namespace = inv.parameters.espejote.namespace;

local TailoredProfile = function(name='') {
  apiVersion: 'compliance.openshift.io/v1alpha1',
  kind: 'TailoredProfile',
  metadata: {
    name: name,
    namespace: params.namespace,
  },
};

local ScanSetting = function(name='') {
  apiVersion: 'compliance.openshift.io/v1alpha1',
  kind: 'ScanSetting',
  metadata: {
    name: name,
    namespace: params.namespace,
  },
};

local ScanSettingBinding = function(name='') {
  apiVersion: 'compliance.openshift.io/v1alpha1',
  kind: 'ScanSettingBinding',
  metadata: {
    name: name,
    namespace: params.namespace,
  },
};

local bindingRefs(obj) = {
  [name]: {
    profiles: [
      {
        apiGroup: 'compliance.openshift.io/v1alpha1',
        kind: 'Profile',
        name: profile,
      }
      for profile in com.renderArray(obj[name].profiles_)
    ] + if std.objectHas(obj[name], 'tailored_') then [
      {
        apiGroup: 'compliance.openshift.io/v1alpha1',
        kind: 'TailoredProfile',
        name: tailored,
      }
      for tailored in com.renderArray(obj[name].tailored_)
    ] else [],
    settingsRef: {
      apiGroup: 'compliance.openshift.io/v1alpha1',
      kind: 'ScanSetting',
      name: obj[name].settingsRef_,
    },
  }
  for name in std.objectFields(obj)
};

local dropNull(obj) = {
  [name]: obj[name]
  for name in std.objectFields(obj)
  if obj[name] != null
};

local tailoredProfiles = com.generateResources(dropNull(params.tailoredProfiles), TailoredProfile);
local scanSettings = com.generateResources(dropNull(params.scanSettings), ScanSetting);
local scanSettingBindings = com.generateResources(bindingRefs(dropNull(params.scanSettingBindings)), ScanSettingBinding);

// Define outputs below
{
  [if std.length(tailoredProfiles) > 0 then '30_tailored_profiles']: tailoredProfiles,
  [if std.length(scanSettings) > 0 then '30_scan_settings']: scanSettings,
  [if std.length(scanSettingBindings) > 0 then '30_scan_setting_bindings']: scanSettingBindings,
}
