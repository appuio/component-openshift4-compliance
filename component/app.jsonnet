local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.openshift4_compliance;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('openshift4-compliance', params.namespace);

local appPath =
  local project = std.get(std.get(app, 'spec', {}), 'project', 'syn');
  if project == 'syn' then 'apps' else 'apps-%s' % project;

{
  ['%s/openshift4-compliance' % appPath]: app,
}
