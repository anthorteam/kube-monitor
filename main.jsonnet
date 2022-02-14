local kp = (import 'kube-prometheus/main.libsonnet') +
(import 'kube-prometheus/addons/all-namespaces.libsonnet') + {
  values+:: {
    common+: {
      platform: 'gke',
      namespace: 'monitoring',
    },
    prometheus+: {
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
              containers:
                std.map(
                  function(c)
                    if c.name == 'grafana' then
                      c {
                        envFrom: [
                          {
                            secretRef: {
                              name: 'grafana-env-config',
                            },
                          },
                        ],
                      }
                    else c,
                  super.containers
                ),
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
          storageClassName: 'standard-encrypted',
        },
      },
    },  
};

{ ['00namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{ ['0prometheus-operator-' + name]: kp.prometheusOperator[name] for name in std.objectFields(kp.prometheusOperator) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
{ ['ambassador-' + name]: kp.ambassador[name] for name in std.objectFields(kp.ambassador)}
