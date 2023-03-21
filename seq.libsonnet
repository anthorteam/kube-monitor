{
  seq+:{
    persistentVolumeClaim+:{
      apiVersion: 'v1',
      kind: 'PersistentVolumeClaim',
      metadata: {
        labels: {
          app: 'seq',
          release: 'prod'
        },
        name: 'seq-log',
        namespace: 'monitoring',
      },
      spec: {
        accessModes: [
          'ReadWriteOnce'
        ],
        resources: {
          requests: {
            storage: '150Gi'
          }
        },
        storageClassName: 'standard',
      }
    },
    deploy+:{
      apiVersion: 'apps/v1',
      kind: 'Deployment',
      metadata: {
        labels: {
            app: 'seq',
            release: 'prod'
        },
        name: 'seq-log',
        namespace: 'monitoring',
      },
      spec: {
        replicas: 1,
        revisionHistoryLimit: 3,
        selector: {
          matchLabels: {
            app: 'seq',
            release: 'prod'
          }
        },
        strategy: {
          type: 'Recreate'
        },
        template: {
          metadata: {
            labels: {
              app: 'seq',
              release: 'prod'
            }
          },
          spec: {
            containers: [
              {
                env: [
                  {
                    name: 'ACCEPT_EULA',
                    value: 'Y'
                  },
                  {
                    name: 'BASE_URI',
                    value: 'https://seq.anthor.co/'
                  },
                  {
                    name: 'SEQ_CACHE_SYSTEMRAMTARGET',
                    value: '0.6'
                  }
                ],
                image: 'gcr.io/anthor-dev/seq:latest',
                imagePullPolicy: 'Always',
                livenessProbe: {
                  failureThreshold: 3,
                  httpGet: {
                      path: '/',
                      port: 'ui',
                      scheme: 'HTTP'
                  },
                  periodSeconds: 10,
                  successThreshold: 1,
                  timeoutSeconds: 1
                },
                name: 'seq',
                ports: [
                  {
                    containerPort: 5341,
                    name: 'ingestion',
                    protocol: 'TCP'
                  },
                  {
                    containerPort: 80,
                    name: 'ui',
                    protocol: 'TCP'
                  }
                ],
                readinessProbe: {
                  failureThreshold: 3,
                  httpGet: {
                    path: '/',
                    port: 'ui',
                    scheme: 'HTTP'
                  },
                  periodSeconds: 10,
                  successThreshold: 1,
                  timeoutSeconds: 1
                },
                resources: {
                  limits: {
                    cpu: '1.5',
                    memory: '2Gi'
                  },
                  requests: {
                    cpu: '0.5',
                    memory: '700Mi'
                  }
                },
                securityContext: {
                  capabilities: {
                    add: [
                      'NET_BIND_SERVICE'
                    ]
                  },
                  runAsUser: 0
                },
                startupProbe: {
                  failureThreshold: 30,
                  httpGet: {
                    path: '/',
                    port: 'ui',
                    scheme: 'HTTP'
                  },
                  periodSeconds: 10,
                  successThreshold: 1,
                  timeoutSeconds: 1
                },
                volumeMounts: [
                  {
                    mountPath: '/data',
                    name: 'seq-data'
                  }
                ]
              }
            ],
            restartPolicy: 'Always',
            volumes: [
              {
                name: 'seq-data',
                persistentVolumeClaim: {
                  claimName: 'seq-log'
                }
              }
            ]
          }
        }
      }
    },
    host+:{
      apiVersion: 'getambassador.io/v3alpha1',
      kind: 'Host',
      metadata: {
        labels: {
            app: 'seq',
            release: 'prod'
        },
        name: 'seq-host',
        namespace: 'ambassador',
      },
      spec: {
        acmeProvider: {
          email: 'mateus.berardo@anthor.com',
        },
        hostname: 'seq.anthor.co',
        requestPolicy: {
          insecure: {
            action: 'Redirect'
          }
        }
      }
    },
    mapping+:{
      apiVersion: 'getambassador.io/v3alpha1',
      kind: 'Mapping',
      metadata: {
        namespace: 'monitoring',
        name: 'seq-mapping'
      },
      spec: {
        docs:{
          ignored: true
        },
        connect_timeout_ms: 30000,
        idle_timeout_ms: 30000,
        timeout_ms: 300000,
        prefix: '/',
        hostname: 'seq.anthor.co',
        serice: 'seq-log.monitoring:80'
      }
    },
  }
}
