FROM odoo:19.0

USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends gettext-base gosu \
 && rm -rf /var/lib/apt/lists/*
RUN pip3 install --no-cache-dir --break-system-packages boto3

COPY --chmod=755 ./entrypoint.sh /odoo-entrypoint.sh
COPY ./addons /mnt/extra-addons
COPY ./odoo.conf /etc/odoo/odoo.conf.template

ENTRYPOINT ["/odoo-entrypoint.sh"]
CMD ["odoo"]
