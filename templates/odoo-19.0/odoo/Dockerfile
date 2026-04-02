FROM odoo:19.0

USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends gettext-base gosu git \
 && rm -rf /var/lib/apt/lists/*
RUN pip3 install --no-cache-dir --break-system-packages boto3

RUN git clone --depth 1 https://github.com/maithanhduyan/s3_attachment.git /mnt/extra-addons/s3_attachment \
 && git clone --depth 1 https://github.com/maithanhduyan/session_redis.git /mnt/extra-addons/session_redis \
 && git clone --depth 1 https://github.com/maithanhduyan/vn_accounting.git /mnt/extra-addons/vn_accounting \
 && rm -rf /mnt/extra-addons/s3_attachment/.git /mnt/extra-addons/session_redis/.git /mnt/extra-addons/vn_accounting/.git

COPY --chmod=755 ./entrypoint.sh /odoo-entrypoint.sh
COPY ./odoo.conf /etc/odoo/odoo.conf.template

ENTRYPOINT ["/odoo-entrypoint.sh"]
CMD ["odoo"]
