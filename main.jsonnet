local kp = (import 'kube-prometheus/main.libsonnet') +
(import 'kube-prometheus/addons/custom-metrics.libsonnet') +
(import 'kube-prometheus/addons/all-namespaces.libsonnet') + {
  values+:: {
    common+: {
      platform: 'gke',
      namespace: 'monitoring',
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
                storageClassName: 'premium-rwo',
              },
            },
          },
        },
      },
      namespaces: [],
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
  grafana+:: {
      deployment+: {
        spec+: {
          template+: {
            spec+: {
              volumes:
                std.map(
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
          accessModes: ['ReadWriteOnce'],
          resources: { requests: { storage: '8Gi' } },
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
{ ['ambassador-' + name]: kp.ambassador[name] for name in std.objectFields(kp.ambassador)}
