#!/usr/bin/env bash
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/sbin:/usr/sbin
DIR_BASE=$(cd ${BASH_SOURCE[0]%/*} && pwd)

. ${DIR_BASE}/../conf/hanat.conf
OWN_INSTANCE_ID=`curl -Lsf --retry 3 --retry-delay 0 http://169.254.169.254/latest/meta-data/instance-id`


log() {
  echo "${1}" | awk '{print strftime("[%Y/%m/%d %H:%M:%S]"), $0}'
}


initialize() {
  log "[info] starting hanat ..."
  (
    sysctl -q -w net.ipv4.ip_forward=1 && \
    sysctl -q -w net.ipv4.conf.eth0.send_redirects=0 && \
    log "[info] set sysctl variables"
  ) && \
  (
    iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2> /dev/null || \
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE && \
    log "[info] added iptables rule"
  ) && \
  (
    aws ec2 modify-instance-attribute --instance-id ${OWN_INSTANCE_ID} --source-dest-check '{"Value": false}' > /dev/null && \
    log "[info] disabled the Source/Dest Check of my own instance"
  ) && \
  (
    for subnet in ${SUBNETS_ACT}; do
      _assoc_id=$(aws --output text ec2 describe-route-tables --query "RouteTables[*].Associations[?SubnetId==\`${subnet}\`].RouteTableAssociationId") && \
      aws ec2 replace-route-table-association --association-id ${_assoc_id} --route-table-id ${RTB_VIA_OWN} > /dev/null && \
      log "[info] configured ${subnet}'s route to ${RTB_VIA_OWN}"
    done
  ) || \
  (
    log "[error] failed initialization"
    return 1
  )
  log "[info] done initialization"
}


failover() {
  for subnet in ${SUBNETS_STB}; do
    (
      _assoc_id=$(aws --output text ec2 describe-route-tables --query "RouteTables[*].Associations[?SubnetId==\`${subnet}\`].RouteTableAssociationId") && \
      aws ec2 replace-route-table-association --association-id ${_assoc_id} --route-table-id ${RTB_VIA_OWN} > /dev/null && \
      log "[info] configured ${subnet}'s route to ${RTB_VIA_OWN}"
    ) || \
    (
      log "[error] failed to configure ${subnet}'s route to ${RTB_VIA_OWN}"
      return 1
    )
  done
  log "[info] done failover"
}


initialize

_partner_failed=0

while :; do
  ${CHECK_PARTNER_CMD} > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    [ ${_partner_failed} -eq 1 ] && log "[info] partner is recovered"
    _partner_failed=0
  else
    log "[info] CHECK_PARTNER_CMD (${CHECK_PARTNER_CMD}) is fail"
    [ ${_partner_failed} -eq 0 ] && failover
    _partner_failed=1
  fi

  sleep ${CHECK_PARTNER_INTVL}
done

