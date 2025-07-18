// main template for openshift4-compliance
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local operatorlib = import 'lib/openshift4-operators.libsonnet';

local inv = kap.inventory();
local params = inv.parameters.openshift4_compliance;

// Namespace

local namespace = kube.Namespace(params.namespace) {
  metadata+: {
    annotations+: {
      'openshift.io/node-selector': '',
      'argocd.argoproj.io/sync-wave': '-100',
    },
    labels+: {
      'openshift.io/cluster-monitoring': 'true',
      'pod-security.kubernetes.io/audit': 'privileged',
      'pod-security.kubernetes.io/enforce': 'privileged',
      'pod-security.kubernetes.io/warn': 'privileged',
    },
  },
};

// OperatorGroup

local operatorGroup = operatorlib.OperatorGroup('compliance-operator') {
  metadata+: {
    annotations+: {
      'argocd.argoproj.io/sync-wave': '-90',
    },
    namespace: params.namespace,
  },
};

// Subscriptions

local subscription = operatorlib.namespacedSubscription(
  params.namespace,
  'compliance-operator',
  params.channel,
  'redhat-operators'
) {
  metadata+: {
    annotations+: {
      'argocd.argoproj.io/sync-wave': '-80',
    },
  },
  spec+: {
    config+: {
      resources: params.operatorResources.compliance,
      affinity: {
        nodeAffinity: {
          requiredDuringSchedulingIgnoredDuringExecution: {
            nodeSelectorTerms: [ {
              matchExpressions: [ {
                key: 'node-role.kubernetes.io/master',
                operator: 'Exists',
              } ],
            } ],
          },
        },
      },
    },
  },
};

// Define outputs below
{
  '00_namespace': namespace,
  '10_operator_group': operatorGroup,
  '20_subscriptions': subscription,
}
+ (import 'resources.libsonnet')
+ (import 'rules-operator.libsonnet')
