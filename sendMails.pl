#!/usr/bin/perl


use lib "/home/cristi/perlModules/";
use DateTimeMail;


my $i; my $mails;
$mails = DateTimeMail->new();
for($i=1;$i<=50;$i++)
{
	print "Send $i \n";
	$mails->SendMail('cristian.nicoara@alcomsib.ro','','cristian.nicoara@sibiu.rdsnet.ro',"Mail Test $i","Teste nemai-intalnite");
}
