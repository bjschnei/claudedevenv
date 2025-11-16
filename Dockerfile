FROM python:3.11

LABEL maintainer="Claude Code Environment" \
      description="Development environment with Claude Code, Agent OS, and Skill_Seekers" \
      version="1.0"

ARG USER=developer
ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/$USER \
    USER=$USER \
    PATH=/home/$USER/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        git \
        ca-certificates \
        gnupg \
        tini \
        vim \
        wget \
        xz-utils \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

RUN NODE_VERSION=20.11.1 \
    && ARCH=$(uname -m | sed 's/aarch64/arm64/;s/x86_64/x64/') \
    && wget -q https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz \
    && tar -xJf node-v${NODE_VERSION}-linux-${ARCH}.tar.xz -C /usr/local --strip-components=1 \
    && rm node-v${NODE_VERSION}-linux-${ARCH}.tar.xz \
    && node --version \
    && npm --version

# Install Docker CLI
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && docker --version

RUN groupadd -g $GID $USER && \
    useradd -u $UID -g $GID -m -s /bin/bash $USER && \
    chown -R $USER:$USER /home/$USER

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

RUN mkdir -p /home/$USER/.claude/debug /home/$USER/.claude/skills /home/$USER/.claude/commands /home/$USER/.claude/agents \
    && touch /home/$USER/.claude/.initialized \
    && chown -R $USER:$USER /home/$USER/.claude

COPY --chown=$USER:$USER --chmod=755 init-claude.sh /home/$USER/

# Copy command templates
COPY --chown=$USER:$USER templates/ /home/$USER/templates/

USER $USER
WORKDIR /home/$USER

# Install Claude Code using the official installer
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && claude --version

RUN git clone --depth=1 https://github.com/yusufkaraaslan/Skill_Seekers.git skill-seekers \
    && rm -rf skill-seekers/.git

RUN curl -fsSL https://raw.githubusercontent.com/buildermethods/agent-os/main/scripts/base-install.sh \
        -o /tmp/base-install.sh \
    && chmod +x /tmp/base-install.sh \
    && /tmp/base-install.sh || echo "Warning: Agent OS installation failed but continuing" \
    && rm -f /tmp/base-install.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD claude --version > /dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/home/developer/init-claude.sh"]
