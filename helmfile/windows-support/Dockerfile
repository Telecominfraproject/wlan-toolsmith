# Setup build arguments with default versions
ARG AWS_CLI_VERSION=1.18.105
ARG TERRAFORM_VERSION=0.12.29
ARG PYTHON_MAJOR_VERSION=3.7
ARG KUBE_VERSION=v1.18.6
ARG HELM_VERSION=v3.2.4

# Download Terraform binary
FROM debian:buster-20191224-slim as terraform
ARG TERRAFORM_VERSION
RUN apt-get update
RUN apt-get install --no-install-recommends -y curl=7.64.0-4+deb10u1
RUN apt-get install --no-install-recommends -y ca-certificates=20190110
RUN apt-get install --no-install-recommends -y unzip=6.0-23+deb10u1
RUN apt-get install --no-install-recommends -y gnupg=2.2.12-1+deb10u1
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig
COPY hashicorp.asc hashicorp.asc
RUN gpg --import hashicorp.asc
RUN gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN grep terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum -c -
RUN unzip -j terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install AWS CLI using PIP
FROM debian:buster-20191224-slim as aws-cli
ARG AWS_CLI_VERSION
ARG PYTHON_MAJOR_VERSION
RUN apt-get update
RUN apt-get install -y --no-install-recommends python3=${PYTHON_MAJOR_VERSION}.3-1
RUN apt-get install -y --no-install-recommends python3-pip=18.1-5
RUN pip3 install setuptools==46.1.3
RUN pip3 install wheel==0.34.2
RUN pip3 install pyyaml==5.3.1
RUN pip3 install awscli==${AWS_CLI_VERSION}

# Download Helm\Kubectl binary
FROM debian:buster-20191224-slim as wget
ARG KUBE_VERSION
ARG HELM_VERSION
RUN apt-get update && \
    apt-get install --no-install-recommends -y wget ca-certificates=20190110
RUN wget -q https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl
RUN wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm

# Build final image
FROM debian:buster-20191224-slim
ARG PYTHON_MAJOR_VERSION
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates=20190110 \
    git \
    curl \
    jq=1.5+dfsg-2+b1 \
    python3=${PYTHON_MAJOR_VERSION}.3-1 \
    sudo \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_MAJOR_VERSION} 1

COPY --from=terraform /terraform /usr/local/bin/terraform
COPY --from=aws-cli /usr/local/bin/aws* /usr/local/bin/
COPY --from=aws-cli /usr/local/lib/python${PYTHON_MAJOR_VERSION}/dist-packages /usr/local/lib/python${PYTHON_MAJOR_VERSION}/dist-packages
COPY --from=aws-cli /usr/lib/python3/dist-packages /usr/lib/python3/dist-packages
COPY --from=wget /usr/local/bin/helm /usr/local/bin/helm
COPY --from=wget /usr/local/bin/kubectl /usr/local/bin/kubectl
# this requires helmfile binary in the same folder with the Dockerfile
COPY helmfile /usr/local/bin/ 
RUN chmod +x /usr/local/bin/helmfile /usr/local/bin/helm /usr/local/bin/kubectl
RUN helm plugin install https://github.com/databus23/helm-diff --version v3.0.0-rc.7 && \
    helm plugin install https://github.com/futuresimple/helm-secrets && \
    helm plugin install https://github.com/hypnoglow/helm-s3.git && \
    helm plugin install https://github.com/aslafy-z/helm-git.git

WORKDIR /workspace
CMD ["bash"]
