FROM bash:5

# Note: Latest version of helm may be found at:
# https://github.com/kubernetes/helm/releases
ENV HELM_VERSION="v3.10.2"

RUN apk add --no-cache ca-certificates git openssh-client \
    && wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && mkdir ~/.ssh \
    && ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

WORKDIR /drone-helm
COPY entrypoint.sh .
RUN chmod 0744 entrypoint.sh

CMD ["/usr/local/bin/bash", "/drone-helm/entrypoint.sh"]
