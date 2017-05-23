HERE=$(dirname $0)
eval $(sh $HERE/../scripts/get_registries.sh)

cat <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: ambassador-certs
  namespace: default
type: Opaque
data: {}
---
apiVersion: v1
kind: Secret
metadata:
  name: ambassador-cacert
  namespace: default
type: Opaque
data: {}
---
apiVersion: v1
kind: Service
metadata:
  labels:
    service: ambassador
  name: ambassador
spec:
  type: ClusterIP
  ports:
  - name: http-ambassador
    port: 80
    targetPort: 80
  selector:
    service: ambassador
---
apiVersion: v1
kind: Service
metadata:
  labels:
    service: aadmin
  name: aadmin
spec:
  type: NodePort
  ports:
  - name: http-aadmin
    port: 8888
    targetPort: 8888
  selector:
    service: ambassador
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: ambassador
spec:
  replicas: 1
  template:
    metadata:
      labels:
        service: ambassador
    spec:
      containers:
      - name: ambassador
        image: ${AMREG}ambassador:0.8.8
        imagePullPolicy: Always
        env:
        - name: AMBASSADOR_DB_HOST
          value: astore
        resources:
          limits:
            cpu: 1
            memory: 400Mi
          requests:
            cpu: 200m
            memory: 100Mi
        volumeMounts:
        - mountPath: /etc/certs
          name: cert-data
        - mountPath: /etc/cacert
          name: cacert-data
      - name: statsd
        image: ${STREG}statsd:0.8.8
      volumes:
      - name: cert-data
        secret:
          secretName: ambassador-certs
      - name: cacert-data
        secret:
          secretName: ambassador-cacert
      restartPolicy: Always
EOF