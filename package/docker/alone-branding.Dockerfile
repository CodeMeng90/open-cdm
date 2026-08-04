ARG BASE_IMAGE=cloudcanal-registry.cn-shanghai.cr.aliyuncs.com/clougence/cgdm-alone:4.0.1
FROM ${BASE_IMAGE}

COPY --chown=root:root clouddm-js.jar /root/cgdm/alone/libs/clouddm-js.jar
