local kp = (import 'kube-prometheus/main.libsonnet') +
(import 'kube-prometheus/addons/custom-metrics.libsonnet') +
(import 'seq.libsonnet') +
(import 'kube-prometheus/addons/all-namespaces.libsonnet') + {
  values+:: {
    common+: {
      namespace: 'monitoring',
    },
    prometheus+:{
      namespaces: [],
    },
    grafana+: {
      dashboards+::{
          'dev-ops.json': (import 'dashboards/DevOps-1648218668076.json'),
          'dev-ops-service.json': (import 'dashboards/DevOps Service-1648218702998.json'),
          'status.json': (import 'dashboards/Status-1648218734942.json'),
      },
      config+: {
        sections: {
          'server': {
            root_url: 'https://grafana.anthor.co'
          },
          'auth.github': {
            enabled: true,
            allow_sign_up: true,
            client_id: '...',
            client_secret: '...',
            scopes: 'user:email,read:org',
            auth_url: 'https://github.com/login/oauth/authorize',
            token_url: 'https://github.com/login/oauth/access_token',
            api_url: 'https://api.github.com/user',
            allowed_organizations: 'anthorteam'
          }
        }
      }
    }
  },
  prometheus+:: {
    prometheus+: {
      spec+: {
        retention: '7d',

        storage: {
          volumeClaimTemplate: {
            apiVersion: 'v1',
            kind: 'PersistentVolumeClaim',
            spec: {
              accessModes: [
                'ReadWriteOnce'
              ],
              resources: {
                requests: {
                 storage: '10Gi'
                }
              },
              storageClassName: 'standard',
            },
          },
        },
      },
    },
  },
  ambassador: {
    serviceMonitorAmbassador: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'ServiceMonitor',
      metadata: {
        name: 'ambassador-monitor',
        namespace: 'ambassador',
        labels: {
          app: 'ambassador',
        },
      },
      spec: {
        namespaceSelector: {
          matchNames: ['ambassador']
        },
        selector: {
          matchLabels: {
            service: 'ambassador-admin'
          }
        },
        endpoints: [
          {
            port: 'ambassador-admin'
          },
        ],
      },
    },
  },
  externalGrafana:{
    grafanaMapping: {
      apiVersion: 'getambassador.io/v2',
      kind: 'Mapping',
      metadata: {
        name: 'grafana-mapping',
        namespace: 'monitoring'
      },
      spec: {
        connect_timeout_ms: 30000,
        docs: {
            ignored: true
        },
        host: 'grafana.anthor.co',
        idle_timeout_ms: 30000,
        prefix: '/',
        service: 'grafana.monitoring:3000',
        timeout_ms: 300000
      }
    },
    grafanaHost: {
      apiVersion: 'getambassador.io/v2',
      kind: 'Host',
      metadata: {
        name: 'grafana-host',
        namespace: 'ambassador',
      },
      spec: {
        acmeProvider: {
          email: 'mateus.berardo@anthor.com',
          privateKeySecret: {
            name: 'grafana-pv-key'
          },
         },
        hostname: 'grafana.anthor.co',
        tlsSecret: {
          name: 'grafana-cert'
        }
      }
    }
  },
  grafana+:: {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            volumes: std.map(
            function(v)
              if v.name == 'grafana-storage' then
                {
                  name: 'grafana-storage',
                  persistentVolumeClaim: {
                    claimName: 'grafana-storage',
                  },
                }
              else v,
            super.volumes
            ),
          },
        },
      },
    },
    storage: {
      apiVersion: 'v1',
      kind: 'PersistentVolumeClaim',
      metadata: {
        namespace: $.values.common.namespace,
        name: 'grafana-storage',
      },
      spec: {
        accessModes: [
          'ReadWriteOnce'
        ],
        resources: {
          requests: {
            storage: '8Gi'
          }
        },
        storageClassName: 'standard',
      },
    },
  },
};

{ 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['ambassador-' + name]: kp.ambassador[name] for name in std.objectFields(kp.ambassador)} +
{ ['grafana-access-' + name]: kp.externalGrafana[name] for name in std.objectFields(kp.externalGrafana)} +
{ ['seq-' + name]: kp.seq[name] for name in std.objectFields(kp.seq)}
