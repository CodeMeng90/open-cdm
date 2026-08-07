ARG BASE_IMAGE=cloudcanal-registry.cn-shanghai.cr.aliyuncs.com/clougence/cgdm-alone:4.0.1
FROM ${BASE_IMAGE}

COPY --chown=root:root clouddm-js.jar /root/cgdm/alone/libs/clouddm-js.jar
COPY --chown=root:root cgdm-console-4.0.1.jar /root/cgdm/alone/libs/cgdm-console-4.0.1.jar
COPY --chown=root:root inner-website-lib.jar /root/cgdm/alone/plugins/inner-website-lib.jar
