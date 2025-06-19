FROM fedora:latest

RUN sudo dnf update -y
RUN sudo dnf install -y git dnf-plugins-core
RUN sudo dnf install -y rpmdevtools rpmlint jq curl

# Create the user
ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
USER $USERNAME
