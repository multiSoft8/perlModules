use SOAP::Transport::HTTP;
use lib "/var/www/soap/";
use backendServer;

SOAP::Transport::HTTP::CGI   
   -> dispatch_to('backendServer')     
   -> handle;

return 1;
