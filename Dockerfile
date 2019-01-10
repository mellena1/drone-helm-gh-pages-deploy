FROM bash:5.0.0

# Note: Latest version of helm may be found at:
# https://github.com/kubernetes/helm/releases
ENV HELM_VERSION="v2.12.1"

RUN apk add --no-cache ca-certificates git \
    && wget -q https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm

WORKDIR /drone-helm
COPY entrypoint.sh .
RUN chmod 0744 entrypoint.sh

CMD ["/usr/local/bin/bash", "/drone-helm/entrypoint.sh"]
