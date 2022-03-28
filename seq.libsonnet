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
            storage: '8Gi'
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
                image: 'datalust/seq:2020',
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
    }
  }
}