#!/usr/bin/perl
use lib "/home/vhosts/status.sibiu.rdsnet.ro/functions/modules";


# Functions
#
###########################################################################################################################################
# GetNextIp(\%params)
#	PARAMETRI
#		$params{ipAddress} 		- ip-ul de la care porneste cautarea (ex: 10.102.120.5 => rezultatul 10.102.120.6)
#		$params{mask}			- mask-ul subnetului din care face parte ip-ul (ex: 255.255.255.248)
#
#	RETURNEAZA
#		NULL				- seteaza in hash-ul params{nextIp} = "10.102.120.4" (ex);
#
#	DESCRIERE	
#		Obtinem urmatorul ip. Ex: avem ip=10.102.120.5,mask=255.255.255.248 obtinem 10.102.120.6
#		Daca ip-ul obtinut este inafara subnetului descris de mask atunci rezultatul este 0.0.0.0
#		Este o functie generica.
############################################################################################################################################
# IsIPFromSubnet(\%params)
#	PARAMETRI
#		$params{ipAddress}		- adresa de verificat
#		$params{network}		- reteaua din care credem ca face parte
#		$params{mask}			- mask subnetului
#
#	RETURNEAZA
#		NULL 				- seteaza in hash-ul params{result} = 10 (daca apartine) , = 1 (daca nu apartine)
#
#	DESCRIERE
#		Verificam daca ipAddress apartine network/mask
#
############################################################################################################################################
#


use MysqlConnection;
package MysqlConnection::IpUtilities;
BEGIN{@ISA = qw ( MysqlConnection );}

sub GetNextIp
{
        my $self = shift;
	my $params = shift;
	my $ip = $params->{ipAddress}; my $mask = $params->{mask};
        my $ipBazaDoi; my $maskBazaDoi; my @vars; my $ipBazaDoiInc; my $error; my $count; my @temps;
        my $ipBazaDoiArray; my @nextIpBazaDoiArray; my $i; my $j; my $isOk = 1; my $nextIp; my $countUnu;
        if($ip eq "0.0.0.0") {return $ip;}
        $ipBazaDoi = ConvertIpDecBin($ip);
        $maskBazaDoi = ConvertIpDecBin($mask);
        $error = IncrementBinNumber($ipBazaDoi,\@vars);
        $ipBazaDoiInc = $vars[0];
        $temps[0] = $maskBazaDoi; $temps[0] =~ s/0//g;
        @temps = split(//,$temps[0]);
        $count = @temps;
        @ipBazaDoiArray = split(//,$ipBazaDoi);
        @nextIpBazaDoiArray = split(//,$ipBazaDoiInc);
        for($i=0;$i<$count;$i++) {if($ipBazaDoiArray[$i] != $nextIpBazaDoiArray[$i]) {$isOk = 0;}}
        if($isOk == 0) 
	{
		$params->{nextIp} = "0.0.0.0";
		return;
	}
        $countUnu = 0;
        for($i=$count;$i<32;$i++){if($nextIpBazaDoiArray[$i] == 1){$countUnu++;}}
        if($countUnu == 32 - $count) 
	{
		$params->{nextIp} = "0.0.0.0";
		return;
	}
        for($i=0;$i<4;$i++)
        {
                $temps[$i] = "";
                for($j=0;$j<8;$j++)
                {
                        $count = $i*8 + $j;
                        $temps[$i] = "$temps[$i]"."$nextIpBazaDoiArray[$count]";
                }
                $temps[$i] = ConvertBinToDec($temps[$i]);
        }
        $nextIp = "$temps[0].$temps[1].$temps[2].$temps[3]";
        $params->{nextIp} = $nextIp;
}


sub IsIPFromSubnet
{
	my $self = shift;
        my $params = shift;
        my $ipAddress = $params->{ipAddress};
        my $network = $params->{network};
        my $mask = $params->{mask};
        my $ipAddressBazaDoi; my $maskBazaDoi; my $networkBazaDoi; my @ipAddressBazaDoiArray; my @networkBazaDoiArray; my $maskBazaDoiArray;
        my $i;
        $ipAddressBazaDoi = ConvertIpDecBin($ipAddress);
#       print "$ipAddressBazaDoi -> ipAddress \n";
        $maskBazaDoi = ConvertIpDecBin($mask);
#       print "$maskBazaDoi -> mask \n";
        $networkBazaDoi = ConvertIpDecBin($network);
#       print "$networkBazaDoi -> network \n";
        @ipAddressBazaDoiArray = split(//,$ipAddressBazaDoi);
        @networkBazaDoiArray = split(//,$networkBazaDoi);
        @maskBazaDoiArray = split(//,$maskBazaDoi);
        for($i=0;$i<32;$i++)
        {
                if($maskBazaDoiArray[$i] == 1 and $networkBazaDoiArray[$i] != $ipAddressBazaDoiArray[$i])
                {

                        $params->{result} = 1; ## daca result=1 atunci ip-ul NU apartine clasei network/mask
                        return;
                }
        }
        $params->{result} = 10; ## daca result=10 atunci ip-ul apartine clasei network/mask
}


sub ConvertDecToBin
{
        my $decValue = shift;
        my $rest; my @binValue; my $cat; my $tempDecValue; my $tempVal; my $i; my $count = 0; my $binValueRet = "";
        $tempDecValue = $decValue;
        do
        {
                $cat = $tempDecValue / 2;
                $cat = int($cat);
                $tempVal = $cat * 2;
                $rest = $tempDecValue - $tempVal;
                $binValue[$count] = $rest;
                $tempDecValue = $cat;
                $count++;
        }while($cat > 0);
        $count--;
        for($i=$count;$i>=0;$i--) {$binValueRet = "$binValueRet"."$binValue[$i]";}
        return $binValueRet;
}

sub ConvertBinToDec
{
        my $binNumber = shift(@_);
        my $decNumber = 0; my $count; my $i; my $ordValue; my @temps; my $j = 0;
        @temps = split(//,$binNumber);
        $count = @temps; $count--;
        for($i=$count;$i>=0;$i--)
        {
                $ordValue = NumberToPower(2,$j);
                $decNumber = $decNumber + $ordValue*$temps[$i];
                $j++;
        }
        return $decNumber;
}


sub ConvertIpDecBin
{
	my $ip = shift;
        my @groupBin; my $i; my $ipBin = "";
        my @groupIp = split(/[.]/,$ip); my @temps; my $count;
        for($i=0;$i<=3;$i++)
        {
                $groupBin[$i] = ConvertDecToBin($groupIp[$i]);
                @temps = split(//,$groupBin[$i]);
                $count = @temps;
                if($count < 8)
                {
                        my $newBin = ""; my $diff = 8 - $count;
                        for($j=0;$j<$diff;$j++) {$newBin = "$newBin"."0";}
                        $groupBin[$i] = "$newBin"."$groupBin[$i]";
                }
                $ipBin = "$ipBin"."$groupBin[$i]";
        }
        return $ipBin;
}

sub IncrementBinNumber
{
        my ($binNumber,$finalValue) = @_;
        $finalValue->[0] = "";
        #finalValue este un pointer al unui tablou si la index 0 se aseaza noul nr binar
        my @temps; my $count; my $i; my $j; my $returnVal = 0;
        @temps = split(//,$binNumber);
        $count = @temps;
        $count--;
        $temps[$count]++;
        for($i=$count;$i>0;$i--)
        {
                $j = $i - 1;
                if($temps[$i] == 2) {$temps[$i] = 0; $temps[$j]++;}
        }
        if($temps[0] == 2) {$temps[0] = 0; $returnVal = 1;}
        for($i=0;$i<=$count;$i++) {$finalValue->[0] = "$finalValue->[0]"."$temps[$i]";}
        return $returnVal;
}

sub NumberToPower
{
        my ($number,$power) = @_;
        my $i; my $rezult = 1;
        for($i=0;$i<$power;$i++) {$rezult = $rezult * $number;}
        return $rezult;
}

return 1;
