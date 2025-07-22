FROM amazonlinux:2

RUN yum install -y unzip curl sudo git && \
    curl -sSLo terraform.zip https://releases.hashicorp.com/terraform/1.12.2/terraform_1.12.2_linux_arm64.zip && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/ && \
    terraform -version

# Optional: Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    aws --version

ENTRYPOINT ["/bin/bash"]