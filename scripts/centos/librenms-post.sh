sudo yum install -y policycoreutils-python
sudo semanage fcontext -a -t httpd_sys_content_t '/opt/librenms/logs(/.*)?'
sudo semanage fcontext -a -t httpd_sys_rw_content_t '/opt/librenms/logs(/.*)?'
sudo restorecon -RFvv /opt/librenms/logs/
sudo semanage fcontext -a -t httpd_sys_content_t '/opt/librenms/rrd(/.*)?'
sudo semanage fcontext -a -t httpd_sys_rw_content_t '/opt/librenms/rrd(/.*)?'
sudo restorecon -RFvv /opt/librenms/rrd/
sudo semanage fcontext -a -t httpd_sys_content_t '/opt/librenms/storage(/.*)?'
sudo semanage fcontext -a -t httpd_sys_rw_content_t '/opt/librenms/storage(/.*)?'
sudo restorecon -RFvv /opt/librenms/storage/
sudo semanage fcontext -a -t httpd_sys_content_t '/opt/librenms/bootstrap/cache(/.*)?'
sudo semanage fcontext -a -t httpd_sys_rw_content_t '/opt/librenms/bootstrap/cache(/.*)?'
sudo restorecon -RFvv /opt/librenms/bootstrap/cache/
sudo setsebool -P httpd_can_sendmail=1
sudo setsebool -P httpd_execmem 1

sudo bash -c 'cat <<EOF > /tmp/http_fping.tt
module http_fping 1.0;

require {
type httpd_t;
class capability net_raw;
class rawip_socket { getopt create setopt write read };
}

#============= httpd_t ==============
allow httpd_t self:capability net_raw;
allow httpd_t self:rawip_socket { getopt create setopt write read };
EOF'

sudo checkmodule -M -m -o /tmp/http_fping.mod /tmp/http_fping.tt
sudo semodule_package -o /tmp/http_fping.pp -m /tmp/http_fping.mod
sudo semodule -i /tmp/http_fping.pp
sudo rm -f /tmp/http_fping.tt /tmp/http_fping.mod /tmp/http_fping.pp

chcon -R -t httpd_cache_t /opt/librenms/html/plugins/Weathermap/
