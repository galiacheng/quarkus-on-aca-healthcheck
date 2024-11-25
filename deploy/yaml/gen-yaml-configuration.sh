cat << EOF > quarkus.yaml
identity:
  type: userAssigned
  userAssignedIdentities: 
   "${UAMI_ID}": {}
properties:
  configuration:
    registries:
      - server: ${LOGIN_SERVER}
        identity: ${UAMI_ID}
    ingress:
      external: true
      allowInsecure: false
      targetPort: 8080
  template:
    revisionSuffix: quarkus-health
    containers:
      - name: ${CONTAINER_APP_NAME}
        image: ${QUARKUS_IMAGE_TAG}
        probes:
          - type: Liveness
            httpGet:
              path: /q/health/live
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 5
          - type: Readiness
            httpGet:
              path: /q/health/ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 3
          - type: Startup
            httpGet:
              path: /q/health/started
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 3
EOF
