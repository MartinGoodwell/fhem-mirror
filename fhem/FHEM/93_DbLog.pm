############################################################################################################################################
# $Id$
#
# 93_DbLog.pm
# written by Dr. Boris Neubert 2007-12-30
# e-mail: omega at online dot de
#
# modified and maintained by Tobias Faust since 2012-06-26
# e-mail: tobias dot faust at online dot de
#
# reduceLog() created by Claudiu Schuster (rapster)
#
############################################################################################################################################
#  Versions History done by DS_Starter & DeeSPe:
#
# 2.13.5     20.02.2017       check presence of table current in DbLog_sampleDataFn
# 2.13.4     18.02.2017       DbLog_Push & DbLog_PushAsync: separate eval-routines for history & current table execution
#                             to decouple commit or rollback transactions, DbLog_sampleDataFn changed to avoid fhem from crash if table
#                             current is not present and DbLogType isn't set
# 2.13.3     18.02.2017       default timeout of DbLog_PushAsync increased to 1800,
#                             delete {HELPER}{xx_PID} in reopen function
# 2.13.2     16.02.2017       deleteOldDaysNbl added (non-blocking implementation of deleteOldDays)
# 2.13.1     15.02.2017       clearReadings limited to readings which won't be recreated periodicly in asynch mode and set readings only blank,
#                             eraseReadings added to delete readings except reading "state",
#                             countNbl non-blocking by DeeSPe,
#                             rename reduceLog non-blocking to reduceLogNbl and implement the old reduceLog too
# 2.13.0     13.02.2017       made reduceLog non-blocking by DeeSPe
# 2.12.5     11.02.2017       add support for primary key of PostgreSQL DB (Rel. 9.5) in both modes for current table
# 2.12.4     09.02.2017       support for primary key of PostgreSQL DB (Rel. 9.5) in both modes only history table
# 2.12.3     07.02.2017       set command clearReadings added
# 2.12.2     07.02.2017       support for primary key of SQLITE DB in both modes
# 2.12.1     05.02.2017       support for primary key of MySQL DB in synch mode
# 2.12       04.02.2017       support for primary key of MySQL DB in asynch mode
# 2.11.4     03.02.2017       check of missing modules added
# 2.11.3     01.02.2017       make errorlogging of DbLog_PushAsync more identical to DbLog_Push 
# 2.11.2     31.01.2017       if attr colEvent, colReading, colValue is set, the limitation of fieldlength is also valid
#                             for SQLite databases
# 2.11.1     30.01.2017       output to central logfile enhanced for DbLog_Push
# 2.11       28.01.2017       DbLog_connect substituted by DbLog_connectPush completely
# 2.10.8     27.01.2017       setinternalcols delayed at fhem start
# 2.10.7     25.01.2017       $hash->{HELPER}{COLSET} in setinternalcols, DbLog_Push changed due to 
#                             issue Turning on AutoCommit failed
# 2.10.6     24.01.2017       DbLog_connect changed "connect_cashed" to "connect", DbLog_Get, chartQuery now uses 
#                             DbLog_ConnectNewDBH, Attr asyncMode changed -> delete reading cacheusage reliable if mode was switched
# 2.10.5     23.01.2017       count, userCommand, deleteOldDays now uses DbLog_ConnectNewDBH
#                             DbLog_Push line 1107 changed
# 2.10.4     22.01.2017       new sub setinternalcols, new attributes colEvent, colReading, colValue
# 2.10.3     21.01.2017       query of cacheEvents changed, attr timeout adjustable
# 2.10.2     19.01.2017       ReduceLog now uses DbLog_ConnectNewDBH -> makes start of ReduceLog stable
# 2.10.1     19.01.2017       commandref edited, cache events don't get lost even if other errors than "db not available" occure  
# 2.10       18.10.2017       new attribute cacheLimit, showNotifyTime
# 2.9.3      17.01.2017       new sub DbLog_ConnectNewDBH (own new dbh for separate use in functions except logging functions),
#                             DbLog_sampleDataFn, dbReadings now use DbLog_ConnectNewDBH
# 2.9.2      16.01.2017       new bugfix for SQLite issue SVGs, DbLog_Log changed to $dev_hash->{CHANGETIME}, DbLog_Push 
#                             changed (db handle new separated)
# 2.9.1      14.01.2017       changed DbLog_ParseEvent to CallInstanceFn, renamed flushCache to purgeCache,
#                             renamed syncCache to commitCache, attr cacheEvents changed to 0,1,2
# 2.9        11.01.2017       changed DbLog_ParseEvent to CallFn
# 2.8.9      11.01.2017       own $dbhp (new DbLog_ConnectPush) for synchronous logging, delete $hash->{HELPER}{RUNNING_PID} 
#                             if DEAD, add func flushCache, syncCache
# 2.8.8      10.01.2017       connection check in Get added, avoid warning "commit/rollback ineffective with AutoCommit enabled"
# 2.8.7      10.01.2017       bugfix no dropdown list in SVG if asynchronous mode activated (func DbLog_sampleDataFn)
# 2.8.6      09.01.2017       Workaround for Warning begin_work failed: Turning off AutoCommit failed, start new timer of
#                             DbLog_execmemcache after reducelog
# 2.8.5      08.01.2017       attr syncEvents, cacheEvents added to minimize events
# 2.8.4      08.01.2017       $readingFnAttributes added
# 2.8.3      08.01.2017       set NOTIFYDEV changed to use notifyRegexpChanged (Forum msg555619), attr noNotifyDev added
# 2.8.2      06.01.2017       commandref maintained to cover new functions
# 2.8.1      05.01.2017       use Time::HiRes qw(gettimeofday tv_interval), bugfix $hash->{HELPER}{RUNNING_PID}
# 2.8        03.01.2017       attr asyncMode, you have a choice to use blocking (as V2.5) or non-blocking asynchronous
#                             with caching, attr showproctime
# 2.7        02.01.2017       initial release non-blocking using BlockingCall
# 2.6        02.01.2017       asynchron writing to DB using cache, attr syncInterval, set listCache
# 2.5        29.12.2016       commandref maintained to cover new attributes, attr "excludeDevs" and "verbose4Devs" now
#                             accepting Regex 
# 2.4.4      28.12.2016       Attribut "excludeDevs" to exclude devices from db-logging (only if $hash->{NOTIFYDEV} eq ".*")
# 2.4.3      28.12.2016       function DbLog_Log: changed separators of @row_array -> better splitting
# 2.4.2      28.12.2016       Attribut "verbose4Devs" to restrict verbose4 loggings of specific devices 
# 2.4.1      27.12.2016       DbLog_Push: improved update/insert into current, analyze execute_array -> ArrayTupleStatus
# 2.4        24.12.2016       some improvements of verbose 4 logging
# 2.3.1      23.12.2016       fix due to https://forum.fhem.de/index.php/topic,62998.msg545541.html#msg545541
# 2.3        22.12.2016       fix eval{} in DbLog_Log
# 2.2        21.12.2016       set DbLogType only to "History" if attr DbLogType not set
# 2.1        21.12.2016       use execute_array in DbLog_Push
# 2.0        19.12.2016       some improvements DbLog_Log
# 1.9.3      17.12.2016       $hash->{NOTIFYDEV} added to process only events from devices are in Regex
# 1.9.2      17.12.2016       some improvemnts DbLog_Log, DbLog_Push
# 1.9.1      16.12.2016       DbLog_Log no using encode_base64
# 1.9        16.12.2016       DbLog_Push changed to use deviceEvents
# 1.8.1      16.12.2016       DbLog_Push changed
# 1.8        15.12.2016       bugfix of don't logging all received events
# 1.7.1      15.12.2016       attr procedure of "disabled" changed


package main;
use strict;
use warnings;
eval "use DBI;1" or my $DbLogMMDBI = "DBI";
use Data::Dumper;
use Blocking;
use Time::HiRes qw(gettimeofday tv_interval);

my $DbLogVersion = "2.13.5";

my %columns = ("DEVICE"  => 64,
               "TYPE"    => 64,
               "EVENT"   => 512,
               "READING" => 64,
               "VALUE"   => 128,
               "UNIT"    => 32
              );
					 
sub dbReadings($@);

################################################################
sub DbLog_Initialize($)
{
  my ($hash) = @_;

  $hash->{DefFn}            = "DbLog_Define";
  $hash->{UndefFn}          = "DbLog_Undef";
  $hash->{NotifyFn}         = "DbLog_Log";
  $hash->{SetFn}            = "DbLog_Set";
  $hash->{GetFn}            = "DbLog_Get";
  $hash->{AttrFn}           = "DbLog_Attr";
  $hash->{SVG_regexpFn}     = "DbLog_regexpFn";
  $hash->{ShutdownFn}       = "DbLog_Shutdown";
  $hash->{AttrList}         = "colEvent ".
                              "colReading ".
							  "colValue ".
                              "disable:1,0 ".
                              "DbLogType:Current,History,Current/History ".
                              "shutdownWait ".
                              "suppressUndef:0,1 ".
		                      "verbose4Devs ".
							  "excludeDevs ".
							  "syncInterval ".
							  "noNotifyDev:1,0 ".
							  "showproctime:1,0 ".
							  "asyncMode:1,0 ".
							  "cacheEvents:2,1,0 ".
							  "cacheLimit ".
							  "syncEvents:1,0 ".
							  "showNotifyTime:1,0 ".
							  "timeout " .
                              "DbLogSelectionMode:Exclude,Include,Exclude/Include ".
							  $readingFnAttributes;

  # Das Attribut DbLogSelectionMode legt fest, wie die Device-Spezifischen Atrribute 
  # DbLogExclude und DbLogInclude behandelt werden sollen.
  #            - Exclude:      Es wird nur das Device-spezifische Attribut Exclude beruecksichtigt, 
  #                                    d.h. generell wird alles geloggt, was nicht per DBLogExclude ausgeschlossen wird
  #            - Include:  Es wird nur das Device-spezifische Attribut Include beruecksichtigt,
  #                                    d.h. generell wird nichts geloggt, ausßer dem was per DBLogInclude eingeschlossen wird
  #            - Exclude/Include:      Es wird zunaechst Exclude geprueft und bei Ausschluß wird ggf. noch zusaetzlich Include geprueft,
  #                                                    d.h. generell wird alles geloggt, es sei denn es wird per DBLogExclude ausgeschlossen.
  #                                                    Wird es von DBLogExclude ausgeschlossen, kann es trotzdem wieder per DBLogInclude
  #                                                    eingeschlossen werden.
  

  addToAttrList("DbLogInclude");
  addToAttrList("DbLogExclude");

  $hash->{FW_detailFn}      = "DbLog_fhemwebFn";
  $hash->{SVG_sampleDataFn} = "DbLog_sampleDataFn";

}

###############################################################
sub DbLog_Define($@)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);
  
  return "Error: Perl module ".$DbLogMMDBI." is missing. 
        Install it on Debian with: sudo apt-get install libdbi-perl" if($DbLogMMDBI);  

  return "wrong syntax: define <name> DbLog configuration regexp"
    if(int(@a) != 4);
  
  $hash->{CONFIGURATION} = $a[2];
  my $regexp             = $a[3];

  eval { "Hallo" =~ m/^$regexp$/ };
  return "Bad regexp: $@" if($@);
  
  $hash->{REGEXP}     = $regexp;
  $hash->{VERSION}    = $DbLogVersion;
  $hash->{MODE}       = "synchronous";   # Standardmode
  
  # nur Events dieser Devices an NotifyFn weiterleiten
  notifyRegexpChanged($hash, $regexp);
  
  #remember PID for plotfork
  $hash->{PID} = $$;
  
  # CacheIndex für Events zum asynchronen Schreiben in DB
  $hash->{cache}{index} = 0;

  # read configuration data
  my $ret = _DbLog_readCfg($hash);
  return $ret if ($ret); # return on error while reading configuration
  
  # set used COLUMNS
  InternalTimer(gettimeofday()+2, "setinternalcols", $hash, 0);

  readingsSingleUpdate($hash, 'state', 'waiting for connection', 1);
  DbLog_ConnectPush($hash);

  # initial execution of DbLog_execmemcache
  DbLog_execmemcache($hash);
  
return undef;
}

################################################################
sub DbLog_Undef($$) {
  my ($hash, $name) = @_;
  my $dbh= $hash->{DBHP};
  BlockingKill($hash->{HELPER}{RUNNING_PID}) if($hash->{HELPER}{RUNNING_PID});
  BlockingKill($hash->{HELPER}{REDUCELOG_PID}) if($hash->{HELPER}{REDUCELOG_PID});
  BlockingKill($hash->{HELPER}{COUNT_PID}) if($hash->{HELPER}{COUNT_PID});
  BlockingKill($hash->{HELPER}{DELDAYS_PID}) if($hash->{HELPER}{DELDAYS_PID});
  $dbh->disconnect() if(defined($dbh));
  RemoveInternalTimer($hash);
  
return undef;
}

################################################################
sub DbLog_Shutdown($) {  
  my ($hash) = @_;
  my $name = $hash->{NAME};
  
  DbLog_execmemcache($hash);
  my $shutdownWait = AttrVal($name,"shutdownWait",undef);
  if(defined($shutdownWait)) {
    Log3($name, 2, "DbLog $name waiting for shutdown");
    sleep($shutdownWait);
  }
  return undef; 
}


################################################################
#
# Wird bei jeder Aenderung eines Attributes dieser
# DbLog-Instanz aufgerufen
#
################################################################
sub DbLog_Attr(@) {
  my($cmd,$name,$aName,$aVal) = @_;
  # my @a = @_;
  my $hash = $defs{$name};
  my $do = 0;

  if($cmd eq "set") {
      if ($aName eq "syncInterval" || $aName eq "cacheLimit" || $aName eq "timeout") {
          unless ($aVal =~ /^[0-9]+$/) { return " The Value of $aName is not valid. Use only figures 0-9 !";}
      }
  }
  
  if($aName eq "colEvent" || $aName eq "colReading" || $aName eq "colValue") {
      if ($cmd eq "set" && $aVal) {
          unless ($aVal =~ /^[0-9]+$/) { return " The Value of $aName is not valid. Use only figures 0-9 !";}
	  }
	  InternalTimer(gettimeofday()+0.5, "setinternalcols", $hash, 0);
  }
  
  if($aName eq "asyncMode") {
      if ($cmd eq "set" && $aVal) {
          $hash->{MODE} = "asynchronous";
		  InternalTimer(gettimeofday()+2, "DbLog_execmemcache", $hash, 0);
      } else {
	      $hash->{MODE} = "synchronous";
          delete($defs{$name}{READINGS}{NextSync});
		  delete($defs{$name}{READINGS}{CacheUsage});
		  InternalTimer(gettimeofday()+5, "DbLog_execmemcache", $hash, 0);
	  }
  }
  
  if($aName eq "showproctime") {
      if ($cmd ne "set" || !$aVal) {
		  delete($defs{$name}{READINGS}{background_processing_time});
		  delete($defs{$name}{READINGS}{sql_processing_time});
	  }
  }
  
  if($aName eq "showNotifyTime") {
      if ($cmd ne "set" || !$aVal) {
		  delete($defs{$name}{READINGS}{notify_processing_time});
	  }
  }
  
  if($aName eq "noNotifyDev") {
      my $regexp = $hash->{REGEXP};
      if ($cmd eq "set" && $aVal) {
	      delete($hash->{NOTIFYDEV});
	  } else {
	      notifyRegexpChanged($hash, $regexp);  
	  }
  }
  
  if ($aName eq "disable") {
      if($cmd eq "set") {
          $do = ($aVal) ? 1 : 0;
      }
      $do = 0 if($cmd eq "del");
      my $val   = ($do == 1 ?  "disabled" : "active");
      
	  # letzter CacheSync vor disablen
	  DbLog_execmemcache($hash) if($do == 1);
	  
      readingsSingleUpdate($hash, "state", $val, 1);
        
      if ($do == 0) {
          InternalTimer(gettimeofday()+2, "DbLog_execmemcache", $hash, 0);
      }
  }

return undef;
}

################################################################
sub DbLog_Set($@) {
    my ($hash, @a) = @_;
	my $name = $hash->{NAME};
	my $usage = "Unknown argument, choose one of reduceLog reduceLogNbl reopen rereadcfg:noArg count:noArg countNbl:noArg 
	             deleteOldDays deleteOldDaysNbl userCommand listCache:noArg purgeCache:noArg commitCache:noArg clearReadings:noArg 
				 eraseReadings:noArg";
	return $usage if(int(@a) < 2);
	my $dbh = $hash->{DBHP};
	my $db  = (split(/;|=/, $hash->{dbconn}))[1];
	my $ret;

    if ($a[1] eq 'reduceLog') {
        if (defined $a[2] && $a[2] =~ /^\d+$/) {
            $ret = DbLog_reduceLog($hash,@a);
			InternalTimer(gettimeofday()+5, "DbLog_execmemcache", $hash, 0);
        } else {
            Log3($name, 1, "DbLog $name: reduceLog error, no <days> given.");
            $ret = "reduceLog error, no <days> given.";
        }
    }
	elsif ($a[1] eq 'reduceLogNbl') {
        if (defined $a[2] && $a[2] =~ /^\d+$/) {
            if ($hash->{HELPER}{REDUCELOG_PID} && $hash->{HELPER}{REDUCELOG_PID}{pid} !~ m/DEAD/) {  
                $ret = "reduceLogNbl already in progress. Please wait for the current process to finish.";
            } else {
			    delete $hash->{HELPER}{REDUCELOG_PID};
			    my @b = @a;
			    shift(@b);
			    readingsSingleUpdate($hash,"reduceLogState","@b started",1);
                $hash->{HELPER}{REDUCELOG} = \@a;
                $hash->{HELPER}{REDUCELOG_PID} = BlockingCall("DbLog_reduceLogNbl","$name","DbLog_reduceLogNbl_finished");
                return;
            }
        } else {
            Log3($name, 1, "DbLog $name: reduceLogNbl error, no <days> given.");
            $ret = "reduceLogNbl error, no <days> given.";
        }
    }
	elsif ($a[1] eq 'clearReadings') {		
        my @allrds = keys%{$defs{$name}{READINGS}};
		foreach my $key(@allrds) {
		    next if($key =~ m/state/ || $key =~ m/CacheUsage/ || $key =~ m/NextSync/);
			readingsSingleUpdate($hash,$key," ",0);
        }
    }
	elsif ($a[1] eq 'eraseReadings') {		
        my @allrds = keys%{$defs{$name}{READINGS}};
		foreach my $key(@allrds) {
            delete($defs{$name}{READINGS}{$key}) if($key !~ m/^state$/);
        }
    }	
    elsif ($a[1] eq 'reopen') {		
		if ($dbh) {
            $dbh->commit() if(!$dbh->{AutoCommit});
            $dbh->disconnect();
        }
		if (!$a[2]) {
		    Log3($name, 3, "DbLog $name: Reopen requested.");
            DbLog_ConnectPush($hash);
            $ret = "Reopen executed.";
		} else {
			unless ($a[2] =~ /^[0-9]+$/) { return " The Value of $a[1]-time is not valid. Use only figures 0-9 !";}
		    # Statusbit "Kein Schreiben in DB erlauben" wenn reopen mit Zeitangabe
            $hash->{HELPER}{REOPEN_RUNS} = 1;
			
			# falls ein hängender Prozess vorhanden ist -> löschen
			BlockingKill($hash->{HELPER}{RUNNING_PID}) if($hash->{HELPER}{RUNNING_PID});
            BlockingKill($hash->{HELPER}{REDUCELOG_PID}) if($hash->{HELPER}{REDUCELOG_PID});
            BlockingKill($hash->{HELPER}{COUNT_PID}) if($hash->{HELPER}{COUNT_PID});
            BlockingKill($hash->{HELPER}{DELDAYS_PID}) if($hash->{HELPER}{DELDAYS_PID});
			delete $hash->{HELPER}{RUNNING_PID};     
			delete $hash->{HELPER}{COUNT_PID};
			delete $hash->{HELPER}{DELDAYS_PID};
			delete $hash->{HELPER}{REDUCELOG_PID};
			
			Log3($name, 3, "DbLog $name: Connection closed. Reopen requested in $a[2] seconds.");
			readingsSingleUpdate($hash, "state", "closed for $a[2] seconds", 1);
            InternalTimer(gettimeofday()+$a[2], "reopen", $hash, 0);			
		}
    }
    elsif ($a[1] eq 'rereadcfg') {
        Log3($name, 3, "DbLog $name: Rereadcfg requested.");
        
        if ($dbh) {
            $dbh->commit() if(!$dbh->{AutoCommit});
            $dbh->disconnect();
        }
        $ret = _DbLog_readCfg($hash);
        return $ret if $ret;
        DbLog_ConnectPush($hash);
        $ret = "Rereadcfg executed.";
    }
	elsif ($a[1] eq 'purgeCache') {
	    delete $hash->{cache};
        readingsSingleUpdate($hash, 'CacheUsage', 0, 1);		
	}
	elsif ($a[1] eq 'commitCache') {
	    DbLog_execmemcache($hash);		
	}
	elsif ($a[1] eq 'listCache') {
	    my $cache;
	    foreach my $key (sort(keys%{$hash->{cache}{memcache}})) {
            $cache .= $key." => ".$hash->{cache}{memcache}{$key}."\n"; 			
		}
	    return $cache;
	}
    elsif ($a[1] eq 'count') {
        $dbh = DbLog_ConnectNewDBH($hash);
        if(!$dbh) {
            Log3($name, 1, "DbLog $name: DBLog_Set - count - DB connect not possible");
			return;
        } else {
            Log3($name, 4, "DbLog $name: Records count requested.");
            
			my $c = $dbh->selectrow_array('SELECT count(*) FROM history');
            readingsSingleUpdate($hash, 'countHistory', $c ,1);
            $c = $dbh->selectrow_array('SELECT count(*) FROM current');
            readingsSingleUpdate($hash, 'countCurrent', $c ,1);
		    $dbh->disconnect();
			
            InternalTimer(gettimeofday()+5, "DbLog_execmemcache", $hash, 0);			
		}
    }
	elsif ($a[1] eq 'countNbl') {
        if ($hash->{HELPER}{COUNT_PID} && $hash->{HELPER}{COUNT_PID}{pid} !~ m/DEAD/){  
            $ret = "DbLog count already in progress. Please wait for the current process to finish.";
        } else {
            delete $hash->{HELPER}{COUNT_PID};
            $hash->{HELPER}{COUNT_PID} = BlockingCall("DbLog_countNbl","$name","DbLog_countNbl_finished");
            return;
        }			
    }
    elsif ($a[1] eq 'deleteOldDays') {
        Log3 ($name, 3, "DbLog $name -> Deletion of records older than $a[2] days in database $db requested");
        my ($c, $cmd);
        
        $dbh = DbLog_ConnectNewDBH($hash);
        if(!$dbh) {
            Log3($name, 1, "DbLog $name: DBLog_Set - deleteOldDays - DB connect not possible");
			return;
        } else {
            $cmd = "delete from history where TIMESTAMP < ";
        
            if ($hash->{DBMODEL} eq 'SQLITE')        { $cmd .= "datetime('now', '-$a[2] days')"; }
            elsif ($hash->{DBMODEL} eq 'MYSQL')      { $cmd .= "DATE_SUB(CURDATE(),INTERVAL $a[2] DAY)"; }
            elsif ($hash->{DBMODEL} eq 'POSTGRESQL') { $cmd .= "NOW() - INTERVAL '$a[2]' DAY"; }
            else { $cmd = undef; $ret = 'Unknown database type. Maybe you can try userCommand anyway.'; }

            if(defined($cmd)) {
                $c = $dbh->do($cmd);
				$c = 0 if($c == 0E0);
				Log3 ($name, 3, "DbLog $name -> deleteOldDays finished. $c entries of database $db deleted.");
                readingsSingleUpdate($hash, 'lastRowsDeleted', $c ,1);
            }
			
			InternalTimer(gettimeofday()+5, "DbLog_execmemcache", $hash, 0);
        }
    }
	elsif ($a[1] eq 'deleteOldDaysNbl') {
        if (defined $a[2] && $a[2] =~ /^\d+$/) {
            if ($hash->{HELPER}{DELDAYS_PID} && $hash->{HELPER}{DELDAYS_PID}{pid} !~ m/DEAD/) {  
                $ret = "deleteOldDaysNbl already in progress. Please wait for the current process to finish.";
            } else {
			    delete $hash->{HELPER}{DELDAYS_PID};
                $hash->{HELPER}{DELDAYS} = $a[2];
				Log3 ($name, 3, "DbLog $name -> Deletion of records older than $a[2] days in database $db requested");
                $hash->{HELPER}{DELDAYS_PID} = BlockingCall("DbLog_deldaysNbl","$name","DbLog_deldaysNbl_done");
                return;
            }
        } else {
            Log3($name, 1, "DbLog $name: reduceLogNbl error, no <days> given.");
            $ret = "reduceLogNbl error, no <days> given.";
        }
    }
    elsif ($a[1] eq 'userCommand') {
        $dbh = DbLog_ConnectNewDBH($hash);
        if(!$dbh) {
            Log3($name, 1, "DbLog $name: DBLog_Set - userCommand - DB connect not possible");
			return;
        } else {
            Log3($name, 4, "DbLog $name: userCommand execution requested.");
            my ($c, @cmd, $sql);
            @cmd = @a;
            shift(@cmd); shift(@cmd);
            $sql = join(" ",@cmd);
            readingsSingleUpdate($hash, 'userCommand', $sql, 1);
            $c = $dbh->selectrow_array($sql);
            readingsSingleUpdate($hash, 'userCommandResult', $c ,1);
			$dbh->disconnect();
			
			InternalTimer(gettimeofday()+5, "DbLog_execmemcache", $hash, 0);
        }
    }
    else { $ret = $usage; }

return $ret;

}

###############################################################################################
#
# Exrahieren des Filters aus der ColumnsSpec (gplot-Datei)
#
# Die grundlegend idee ist das jeder svg plot einen filter hat der angibt 
# welches device und reading dargestellt wird so das der plot sich neu 
# lädt wenn es ein entsprechendes event gibt. 
#
# Parameter: Quell-Instanz-Name, und alle FileLog-Parameter, die diese Instanz betreffen.
# Quelle: http://forum.fhem.de/index.php/topic,40176.msg325200.html#msg325200
###############################################################################################
sub DbLog_regexpFn($$) {                            
  my ($name, $filter) = @_;
  my $ret;
 
  my @a = split( ' ', $filter );
  for(my $i = 0; $i < int(@a); $i++) {
    my @fld = split(":", $a[$i]);

    $ret .= '|' if( $ret );
    $ret .=  $fld[0] .'.'. $fld[1];
  }                  

  return $ret;
}

################################################################
#
# Parsefunktion, abhaengig vom Devicetyp
#
################################################################
sub DbLog_ParseEvent($$$)
{
  my ($device, $type, $event)= @_;
  my @result;
  my $reading;
  my $value;
  my $unit;

  # Splitfunktion der Eventquelle aufrufen (ab 2.9.1)
  ($reading, $value, $unit) = CallInstanceFn($device, "DbLog_splitFn", $event, $device);
  # undef bedeutet, Modul stellt keine DbLog_splitFn bereit
  if($reading) {
      return ($reading, $value, $unit);
  }

  # split the event into reading, value and unit
  # "day-temp: 22.0 (Celsius)" -> "day-temp", "22.0 (Celsius)"
  my @parts   = split(/: /,$event);
  $reading = shift @parts;
  if(@parts == 2) { 
    $value = $parts[0];
    $unit  = $parts[1];
  } else {
    $value   = join(": ", @parts);
    $unit    = "";
  } 

  #default
  if(!defined($reading)) { $reading = ""; }
  if(!defined($value))   { $value   = ""; }
  if( $value eq "" ) {
    $reading= "state";
    $value= $event;
  }

  #globales Abfangen von 
  # - temperature
  # - humidity
  if   ($reading =~ m(^temperature)) { $unit= "°C"; } # wenn reading mit temperature beginnt
  elsif($reading =~ m(^humidity)) { $unit= "%"; }


  # the interpretation of the argument depends on the device type
  # EMEM, M232Counter, M232Voltage return plain numbers
  if(($type eq "M232Voltage") ||
     ($type eq "M232Counter") ||
     ($type eq "EMEM")) {
  }
  #OneWire 
  elsif(($type eq "OWMULTI")) {
    if(int(@parts)>1) {
      $reading = "data";
      $value = $event;
    } else {
      @parts = split(/\|/, AttrVal($device, $reading."VUnit", ""));
      $unit = $parts[1] if($parts[1]);
      if(lc($reading) =~ m/temp/) {
        $value=~ s/ \(Celsius\)//;
        $value=~ s/([-\.\d]+).*/$1/;
        $unit= "°C";
      }
      elsif(lc($reading) =~ m/(humidity|vwc)/) { 
        $value=~ s/ \(\%\)//; 
        $unit= "%"; 
      }
    }
  }
  # Onewire
  elsif(($type eq "OWAD") ||
        ($type eq "OWSWITCH")) {
      if(int(@parts)>1) {
        $reading = "data";
        $value = $event;
      } else {
        @parts = split(/\|/, AttrVal($device, $reading."Unit", ""));
        $unit = $parts[1] if($parts[1]);
      }
  }

  # FBDECT
  elsif (($type eq "FBDECT")) {
    if ( $value=~/([\.\d]+)\s([a-z])/i ) {
     $value = $1;
     $unit  = $2;
    }
  }

  # MAX
  elsif(($type eq "MAX")) {
    $unit= "°C" if(lc($reading) =~ m/temp/);
    $unit= "%"   if(lc($reading) eq "valveposition");
  }

  # FS20
  elsif(($type eq "FS20") ||
        ($type eq "X10")) {
    if($reading =~ m/^dim(\d+).*/o) {
      $value = $1;
      $reading= "dim";
      $unit= "%";
    }
    elsif(!defined($value) || $value eq "") {
      $value= $reading;
      $reading= "data";
    }
  }

  # FHT
  elsif($type eq "FHT") {
    if($reading =~ m(-from[12]\ ) || $reading =~ m(-to[12]\ )) {
      @parts= split(/ /,$event);
      $reading= $parts[0];
      $value= $parts[1];
      $unit= "";
    }
    elsif($reading =~ m(-temp)) { $value=~ s/ \(Celsius\)//; $unit= "°C"; }
    elsif($reading =~ m(temp-offset)) { $value=~ s/ \(Celsius\)//; $unit= "°C"; }
    elsif($reading =~ m(^actuator[0-9]*)) {
      if($value eq "lime-protection") {
        $reading= "actuator-lime-protection";
        undef $value;
      }
      elsif($value =~ m(^offset:)) {
        $reading= "actuator-offset";
        @parts= split(/: /,$value);
        $value= $parts[1];
        if(defined $value) {
          $value=~ s/%//; $value= $value*1.; $unit= "%";
        }
      }
      elsif($value =~ m(^unknown_)) {
        @parts= split(/: /,$value);
        $reading= "actuator-" . $parts[0];
        $value= $parts[1];
        if(defined $value) {
          $value=~ s/%//; $value= $value*1.; $unit= "%";
        }
      }
      elsif($value =~ m(^synctime)) {
        $reading= "actuator-synctime";
        undef $value;
      }
      elsif($value eq "test") {
        $reading= "actuator-test";
        undef $value;
      }
      elsif($value eq "pair") {
        $reading= "actuator-pair";
        undef $value;
      }
      else {
        $value=~ s/%//; $value= $value*1.; $unit= "%";
      }
    }
  }
  # KS300
  elsif($type eq "KS300") {
    if($event =~ m(T:.*)) { $reading= "data"; $value= $event; }
    elsif($event =~ m(avg_day)) { $reading= "data"; $value= $event; }
    elsif($event =~ m(avg_month)) { $reading= "data"; $value= $event; }
    elsif($reading eq "temperature") { $value=~ s/ \(Celsius\)//; $unit= "°C"; }
    elsif($reading eq "wind") { $value=~ s/ \(km\/h\)//; $unit= "km/h"; }
    elsif($reading eq "rain") { $value=~ s/ \(l\/m2\)//; $unit= "l/m2"; }
    elsif($reading eq "rain_raw") { $value=~ s/ \(counter\)//; $unit= ""; }
    elsif($reading eq "humidity") { $value=~ s/ \(\%\)//; $unit= "%"; }
    elsif($reading eq "israining") {
      $value=~ s/ \(yes\/no\)//;
      $value=~ s/no/0/;
      $value=~ s/yes/1/;
    }
  }
  # HMS
  elsif($type eq "HMS" ||
        $type eq "CUL_WS" ||
        $type eq "OWTHERM") {
    if($event =~ m(T:.*)) { $reading= "data"; $value= $event; }
    elsif($reading eq "temperature") {
      $value=~ s/ \(Celsius\)//; 
      $value=~ s/([-\.\d]+).*/$1/; #OWTHERM
      $unit= "°C"; 
    }
    elsif($reading eq "humidity") { $value=~ s/ \(\%\)//; $unit= "%"; }
    elsif($reading eq "battery") {
      $value=~ s/ok/1/;
      $value=~ s/replaced/1/;
      $value=~ s/empty/0/;
    }
  }
  # CUL_HM
  elsif ($type eq "CUL_HM") {
    # remove trailing %  
    $value=~ s/ \%$//;
  }

  # BS
  elsif($type eq "BS") {
    if($event =~ m(brightness:.*)) {
      @parts= split(/ /,$event);
      $reading= "lux";
      $value= $parts[4]*1.;
      $unit= "lux";
    }
  }

  # RFXTRX Lighting
  elsif($type eq "TRX_LIGHT") {
    if($reading =~ m/^level (\d+)/) {
        $value = $1;
        $reading= "level";
    }
  }

  # RFXTRX Sensors
  elsif($type eq "TRX_WEATHER") {
    if($reading eq "energy_current") { $value=~ s/ W//; }
    elsif($reading eq "energy_total") { $value=~ s/ kWh//; }
#    elsif($reading eq "temperature") {TODO}
#    elsif($reading eq "temperature")  {TODO
    elsif($reading eq "battery") {
      if ($value=~ m/(\d+)\%/) { 
        $value= $1; 
      }
      else {
        $value= ($value eq "ok");
      }
    }
  }

  # Weather
  elsif($type eq "WEATHER") {
    if($event =~ m(^wind_condition)) {
      @parts= split(/ /,$event); # extract wind direction from event
      if(defined $parts[0]) {
        $reading = "wind_direction";
        $value= $parts[2];
      }
    }
    elsif($reading eq "wind_chill") { $unit= "°C"; }
    elsif($reading eq "wind_direction") { $unit= ""; }
    elsif($reading =~ m(^wind)) { $unit= "km/h"; } # wind, wind_speed
    elsif($reading =~ m(^temperature)) { $unit= "°C"; } # wenn reading mit temperature beginnt
    elsif($reading =~ m(^humidity)) { $unit= "%"; }
    elsif($reading =~ m(^pressure)) { $unit= "hPa"; }
    elsif($reading =~ m(^pressure_trend)) { $unit= ""; }
  }

  # FHT8V
  elsif($type eq "FHT8V") {
    if($reading =~ m(valve)) {
      @parts= split(/ /,$event);
      $reading= $parts[0];
      $value= $parts[1];
      $unit= "%";
    }
  }

  # Dummy
  elsif($type eq "DUMMY")  {
    if( $value eq "" ) {
      $reading= "data";
      $value= $event;
    }
    $unit= "";
  }

  @result= ($reading,$value,$unit);
  return @result;
}

##################################################################################################################
#
# Hauptroutine zum Loggen. Wird bei jedem Eventchange
# aufgerufen
#
##################################################################################################################
# Es werden nur die Events von Geräten verarbeitet die im Hash $hash->{NOTIFYDEV} gelistet sind (wenn definiert).
# Dadurch kann die Menge der Events verringert werden. In sub DbRep_Define angeben.
# Beispiele:
# $hash->{NOTIFYDEV} = "global";
# $hash->{NOTIFYDEV} = "global,Definition_A,Definition_B";

sub DbLog_Log($$) {
  # $hash is my entry, $dev_hash is the entry of the changed device
  my ($hash, $dev_hash) = @_;
  my $name     = $hash->{NAME};
  my $dev_name = $dev_hash->{NAME};
  my $dev_type = uc($dev_hash->{TYPE});
  my $async    = AttrVal($name, "asyncMode", undef);
  my $clim     = AttrVal($name, "cacheLimit", 500);
  my $ce       = AttrVal($name, "cacheEvents", 0);
  my $net;

  return if(IsDisabled($name) || !$hash->{HELPER}{COLSET} || $init_done != 1);

  # Notify-Routine Startzeit
  my $nst = [gettimeofday];
  
  my $events = deviceEvents($dev_hash,0);  
  return if(!$events);
  
  my $lcdev    = lc($dev_name);
  
  # verbose4 Logs nur für Devices in Attr "verbose4Devs"
  my $vb4show  = 0;
  my @vb4devs  = split(",", AttrVal($name, "verbose4Devs", ""));
  if (!@vb4devs) {
      $vb4show = 1;
  } else {
      foreach (@vb4devs) {
	      if($dev_name =~ m/$_/i) {
		      $vb4show = 1;
			  last;
		  }
	  }
	  Log3 $name, 4, "DbLog $name -> verbose 4 output of device $dev_name skipped due to attribute \"verbose4Devs\" restrictions" if(!$vb4show);
  }
  
  # Devices ausschließen durch Attribut "excludeDevs" (nur wenn kein $hash->{NOTIFYDEV} oder $hash->{NOTIFYDEV} = .*)
  if(!$hash->{NOTIFYDEV} || $hash->{NOTIFYDEV} eq ".*") {
      my @exdevs  = split(",", AttrVal($name, "excludeDevs", ""));
	  if(@exdevs) {
	      foreach (@exdevs) {
		      if($dev_name =~ m/$_/i) {
	              Log3 $name, 4, "DbLog $name -> Device: $dev_name excluded from database logging due to attribute \"excludeDevs\" restrictions" if($vb4show);
	              return;
		      }
		  }
	  }
  }
  
  my $re                 = $hash->{REGEXP};
  my $max                = int(@{$events});
  my @row_array;
  my ($event,$reading,$value,$unit);
  my $ts_0               = TimeNow();                                    # timestamp in SQL format YYYY-MM-DD hh:mm:ss
  my $now                = gettimeofday();                               # get timestamp in seconds since epoch
  my $DbLogExclude       = AttrVal($dev_name, "DbLogExclude", undef);
  my $DbLogInclude       = AttrVal($dev_name, "DbLogInclude",undef);
  my $DbLogSelectionMode = AttrVal($name, "DbLogSelectionMode","Exclude");  
  
  if($vb4show) {
      Log3 $name, 4, "DbLog $name -> ################################################################";
      Log3 $name, 4, "DbLog $name -> ###              start of new Logcycle                       ###";
      Log3 $name, 4, "DbLog $name -> ################################################################";
      Log3 $name, 4, "DbLog $name -> amount of events received: $max for device: $dev_name";
  }
  
  #one Transaction
  eval {  
      for (my $i = 0; $i < $max; $i++) {
	      my $event = $dev_hash->{CHANGED}[$i];
          Log3 $name, 4, "DbLog $name -> check Device: $dev_name , Event: $event" if($vb4show);
          $event = "" if(!defined($event));  
	  
	      if($dev_name =~ m/^$re$/ || "$dev_name:$event" =~ m/^$re$/ || $DbLogSelectionMode eq 'Include') {
			  my $timestamp = $ts_0;
              $timestamp = $dev_hash->{CHANGETIME}[$i] if(defined($dev_hash->{CHANGETIME}[$i]));
              
              my @r = DbLog_ParseEvent($dev_name, $dev_type, $event);
			  $reading = $r[0];
              $value   = $r[1];
              $unit    = $r[2];
              if(!defined $reading) {$reading = "";}
              if(!defined $value) {$value = "";}
              if(!defined $unit || $unit eq "") {$unit = AttrVal("$dev_name", "unit", "");}

              #Je nach DBLogSelectionMode muss das vorgegebene Ergebnis der Include-, bzw. Exclude-Pruefung
              #entsprechend unterschiedlich vorbelegt sein.
              #keine Readings loggen die in DbLogExclude explizit ausgeschlossen sind
              my $DoIt = 0;
              $DoIt = 1 if($DbLogSelectionMode =~ m/Exclude/ );
          
		      if($DbLogExclude && $DbLogSelectionMode =~ m/Exclude/) {
                  # Bsp: "(temperature|humidity):300 battery:3600"
                  my @v1 = split(/,/, $DbLogExclude);
              
			      for (my $i=0; $i<int(@v1); $i++) {
                      my @v2 = split(/:/, $v1[$i]);
                      $DoIt = 0 if(!$v2[1] && $reading =~ m/^$v2[0]$/); #Reading matcht auf Regexp, kein MinIntervall angegeben
                  
				      if(($v2[1] && $reading =~ m/^$v2[0]$/) && ($v2[1] =~ m/^(\d+)$/)) {
                          #Regexp matcht und MinIntervall ist angegeben
                          my $lt = $defs{$dev_hash->{NAME}}{Helper}{DBLOG}{$reading}{$hash->{NAME}}{TIME};
                          my $lv = $defs{$dev_hash->{NAME}}{Helper}{DBLOG}{$reading}{$hash->{NAME}}{VALUE};
                          $lt = 0 if(!$lt);
                          $lv = "" if(!$lv);

                          if(($now-$lt < $v2[1]) && ($lv eq $value)) {
                              # innerhalb MinIntervall und LastValue=Value
                              $DoIt = 0;
                          }
                      }
                  }
              }
        
		      #Hier ggf. zusaetlich noch dbLogInclude pruefen, falls bereits durch DbLogExclude ausgeschlossen
              #Im Endeffekt genau die gleiche Pruefung, wie fuer DBLogExclude, lediglich mit umgegkehrtem Ergebnis.
              if($DoIt == 0) {
                  if($DbLogInclude && ($DbLogSelectionMode =~ m/Include/)) {
                      my @v1 = split(/,/, $DbLogInclude);
              
			          for (my $i=0; $i<int(@v1); $i++) {
                          my @v2 = split(/:/, $v1[$i]);
                          $DoIt = 1 if($reading =~ m/^$v2[0]$/); #Reading matcht auf Regexp
                  
				          if(($v2[1] && $reading =~ m/^$v2[0]$/) && ($v2[1] =~ m/^(\d+)$/)) {
                              #Regexp matcht und MinIntervall ist angegeben
                              my $lt = $defs{$dev_hash->{NAME}}{Helper}{DBLOG}{$reading}{$hash->{NAME}}{TIME};
                              my $lv = $defs{$dev_hash->{NAME}}{Helper}{DBLOG}{$reading}{$hash->{NAME}}{VALUE};
                              $lt = 0 if(!$lt);
                              $lv = "" if(!$lv);
       
                              if(($now-$lt < $v2[1]) && ($lv eq $value)) {
                                  # innerhalb MinIntervall und LastValue=Value
                                  $DoIt = 0;
                              }
                          }
                      }
                  }
              }
              next if($DoIt == 0);
		
	    	  if ($DoIt) {
                  $defs{$dev_name}{Helper}{DBLOG}{$reading}{$hash->{NAME}}{TIME}  = $now;
                  $defs{$dev_name}{Helper}{DBLOG}{$reading}{$hash->{NAME}}{VALUE} = $value;
			      
				  my $colevent   = AttrVal($name, 'colEvent', undef);
				  my $colreading = AttrVal($name, 'colReading', undef);
				  my $colvalue   = AttrVal($name, 'colValue', undef);
	              if ($hash->{DBMODEL} ne 'SQLITE' || defined($colevent) || defined($colreading) || defined($colvalue) ) {
                      # Daten auf maximale Länge beschneiden
                      $dev_name = substr($dev_name,0, $hash->{HELPER}{DEVICECOL});
                      $dev_type = substr($dev_type,0, $hash->{HELPER}{TYPECOL});
                      $event    = substr($event,0, $hash->{HELPER}{EVENTCOL});
                      $reading  = substr($reading,0, $hash->{HELPER}{READINGCOL});
                      $value    = substr($value,0, $hash->{HELPER}{VALUECOL});
                      $unit     = substr($unit,0, $hash->{HELPER}{UNITCOL});
                  }
  
			      my $row = ($timestamp."|".$dev_name."|".$dev_type."|".$event."|".$reading."|".$value."|".$unit);
				  Log3 $hash->{NAME}, 4, "DbLog $name -> added event - Timestamp: $timestamp, Device: $dev_name, Type: $dev_type, Event: $event, Reading: $reading, Value: $value, Unit: $unit"
				                          if($vb4show);	
                  
				  if($async) {
				      # asynchoner non-blocking Mode
					  # Cache & CacheIndex für Events zum asynchronen Schreiben in DB
					  $hash->{cache}{index}++;
				      my $index = $hash->{cache}{index};
				      $hash->{cache}{memcache}{$index} = $row;
					  
					  my $memcount = $hash->{cache}{memcache}?scalar(keys%{$hash->{cache}{memcache}}):0;
	                  if($ce == 1) {
                          readingsSingleUpdate($hash, "CacheUsage", $memcount, 1); 
	                  } else {
	                      readingsSingleUpdate($hash, 'CacheUsage', $memcount, 0); 
	                  }
					  # asynchrone Schreibroutine aufrufen wenn Füllstand des Cache erreicht ist
					  if($memcount >= $clim) {
					      Log3 $hash->{NAME}, 5, "DbLog $name -> Number of cache entries reached cachelimit $clim - start database sync.";
					      DbLog_execmemcache($hash);
					  }
					  # Notify-Routine Laufzeit ermitteln
                      $net = tv_interval($nst);
				  } else {
				      # synchoner Mode
				      push(@row_array, $row);		
				  }  
              }		  
          }
      }
  }; 
  if(!$async) {    
      if(@row_array) {
	      # synchoner Mode
		  # return wenn "reopen" mit Ablaufzeit gestartet ist
          return if($hash->{HELPER}{REOPEN_RUNS});	  
          my $error = DbLog_Push($hash, $vb4show, @row_array);
          Log3 $name, 5, "DbLog $name -> DbLog_Push Returncode: $error" if($vb4show);
		  if($error) {
              readingsSingleUpdate($hash, "state", $error, 1);
		  } else {
		      readingsSingleUpdate($hash, "state", "connected", 0);
		  }
		  # Notify-Routine Laufzeit ermitteln
          $net = tv_interval($nst);
      }
  }
  if($net && AttrVal($name, "showNotifyTime", undef)) {
      readingsSingleUpdate($hash, "notify_processing_time", sprintf("%.4f",$net), 1);
  }
return;
}

#################################################################################################
#
# Schreibroutine Einfügen Werte in DB im Synchronmode 
#
#################################################################################################
sub DbLog_Push(@) {
  my ($hash, $vb4show, @row_array) = @_;
  my $name       = $hash->{NAME};
  my $DbLogType  = AttrVal($name, "DbLogType", "History");
  my $errorh      = 0;
  my $errorc      = 0;
  my $error       = 0;
  my $doins = 0;  # Hilfsvariable, wenn "1" sollen inserts in Tabele current erfolgen (updates schlugen fehl) 
  my $dbh;
  
  $dbh = $hash->{DBHP};
  eval {
      if ( !$dbh || not $dbh->ping ) {
          #### DB Session dead, try to reopen now !
          DbLog_ConnectPush($hash);
      }  
  };
  if ($@) {
      Log3($name, 1, "DbLog $name: DBLog_Push - DB Session dead! - $@");
	  return $@;
  } else {
      $dbh = $hash->{DBHP};
  } 
  
  $dbh->{RaiseError} = 1; 
  $dbh->{PrintError} = 0;
  
  # check ob PK verwendet wird, @usepkx?Anzahl der Felder im PK:0 wenn kein PK, $pkx?Namen der Felder:none wenn kein PK 
  my ($usepkh,$usepkc,$pkh,$pkc) = checkUsePK($hash,$dbh);
  
  my (@timestamp,@device,@type,@event,@reading,@value,@unit);
  my (@timestamp_cur,@device_cur,@type_cur,@event_cur,@reading_cur,@value_cur,@unit_cur);
  my ($sth_ih,$sth_ic,$sth_uc);
  no warnings 'uninitialized';
  
  my $ceti = $#row_array+1;
  
  foreach my $row (@row_array) {
      my @a = split("\\|",$row);
	  push(@timestamp, "$a[0]"); 
	  push(@device, "$a[1]");   
	  push(@type, "$a[2]");  
	  push(@event, "$a[3]");  
	  push(@reading, "$a[4]"); 
	  push(@value, "$a[5]"); 
	  push(@unit, "$a[6]"); 
	  Log3 $hash->{NAME}, 4, "DbLog $name -> processing event Timestamp: $a[0], Device: $a[1], Type: $a[2], Event: $a[3], Reading: $a[4], Value: $a[5], Unit: $a[6]"
							 if($vb4show);
  }	  
  use warnings;
	
  if (lc($DbLogType) =~ m(history)) {
      # insert history mit/ohne primary key
	  if ($usepkh && $hash->{DBMODEL} eq 'MYSQL') {
	      eval { $sth_ih = $dbh->prepare("INSERT IGNORE INTO history (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)"); };
	  } elsif ($usepkh && $hash->{DBMODEL} eq 'SQLITE') {
	      eval { $sth_ih = $dbh->prepare("INSERT OR IGNORE INTO history (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)"); };
	  } elsif ($usepkh && $hash->{DBMODEL} eq 'POSTGRESQL') {
	      eval { $sth_ih = $dbh->prepare("INSERT INTO history (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?) ON CONFLICT DO NOTHING"); };
	  } else {
	      # old behavior
	      eval { $sth_ih = $dbh->prepare("INSERT INTO history (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)"); };
	  }
	  if ($@) {
	      return $@;
      }
      $sth_ih->bind_param_array(1, [@timestamp]);
      $sth_ih->bind_param_array(2, [@device]);
      $sth_ih->bind_param_array(3, [@type]);
      $sth_ih->bind_param_array(4, [@event]);
      $sth_ih->bind_param_array(5, [@reading]);
      $sth_ih->bind_param_array(6, [@value]);
      $sth_ih->bind_param_array(7, [@unit]);
  }
  
  if (lc($DbLogType) =~ m(current) ) {
      # insert current mit/ohne primary key, insert-values für current werden generiert
	  if ($usepkc && $hash->{DBMODEL} eq 'MYSQL') {
          eval { $sth_ic = $dbh->prepare("INSERT IGNORE INTO current (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)"); };	  
	  } elsif ($usepkc && $hash->{DBMODEL} eq 'SQLITE') {
	      eval { $sth_ic = $dbh->prepare("INSERT OR IGNORE INTO current (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)"); };
	  } elsif ($usepkc && $hash->{DBMODEL} eq 'POSTGRESQL') {
	      eval { $sth_ic = $dbh->prepare("INSERT INTO current (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?) ON CONFLICT DO NOTHING"); };
	  }  else {
	      # old behavior
	      eval { $sth_ic = $dbh->prepare("INSERT INTO current (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)"); };
	  }
	  if ($@) {
	      return $@;
      }
	  if ($usepkc && $hash->{DBMODEL} eq 'MYSQL') {
	      # update current (mit PK), insert-values für current wird generiert
		  $sth_uc = $dbh->prepare("REPLACE INTO current (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)");
	      $sth_uc->bind_param_array(1, [@timestamp]);
          $sth_uc->bind_param_array(2, [@device]);
          $sth_uc->bind_param_array(3, [@type]);
          $sth_uc->bind_param_array(4, [@event]);
		  $sth_uc->bind_param_array(5, [@reading]);
          $sth_uc->bind_param_array(6, [@value]);
          $sth_uc->bind_param_array(7, [@unit]);  
	  } elsif ($usepkc && $hash->{DBMODEL} eq 'SQLITE') {  
	      # update current (mit PK), insert-values für current wird generiert
		  $sth_uc = $dbh->prepare("INSERT OR REPLACE INTO current (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)");
	      $sth_uc->bind_param_array(1, [@timestamp]);
          $sth_uc->bind_param_array(2, [@device]);
          $sth_uc->bind_param_array(3, [@type]);
          $sth_uc->bind_param_array(4, [@event]);
		  $sth_uc->bind_param_array(5, [@reading]);
          $sth_uc->bind_param_array(6, [@value]);
          $sth_uc->bind_param_array(7, [@unit]);
	  } elsif ($usepkc && $hash->{DBMODEL} eq 'POSTGRESQL') {  
	      # update current (mit PK), insert-values für current wird generiert
		  $sth_uc = $dbh->prepare("INSERT INTO current (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?) ON CONFLICT ($pkc) 
		                           DO UPDATE SET TIMESTAMP=EXCLUDED.TIMESTAMP, DEVICE=EXCLUDED.DEVICE, TYPE=EXCLUDED.TYPE, EVENT=EXCLUDED.EVENT, READING=EXCLUDED.READING,
								   VALUE=EXCLUDED.VALUE, UNIT=EXCLUDED.UNIT");
	      $sth_uc->bind_param_array(1, [@timestamp]);
          $sth_uc->bind_param_array(2, [@device]);
          $sth_uc->bind_param_array(3, [@type]);
          $sth_uc->bind_param_array(4, [@event]);
		  $sth_uc->bind_param_array(5, [@reading]);
          $sth_uc->bind_param_array(6, [@value]);
          $sth_uc->bind_param_array(7, [@unit]);
	  } else {	  
	      # for update current (ohne PK), insert-values für current wird generiert
	      $sth_uc = $dbh->prepare("UPDATE current SET TIMESTAMP=?, TYPE=?, EVENT=?, VALUE=?, UNIT=? WHERE (DEVICE=?) AND (READING=?)");
	      $sth_uc->bind_param_array(1, [@timestamp]);
          $sth_uc->bind_param_array(2, [@type]);
          $sth_uc->bind_param_array(3, [@event]);
          $sth_uc->bind_param_array(4, [@value]);
          $sth_uc->bind_param_array(5, [@unit]);
          $sth_uc->bind_param_array(6, [@device]);
          $sth_uc->bind_param_array(7, [@reading]);
	  }
  }
  
  my ($tuples, $rows);
  
  # insert into history-Tabelle
  eval {$dbh->begin_work();};  # issue:  begin_work failed: Turning off AutoCommit failed
  if ($@) {
      Log3($name, 2, "DbLog $name -> Error start transaction for history - $@");
  }
  eval {
      if (lc($DbLogType) =~ m(history) ) {
          ($tuples, $rows) = $sth_ih->execute_array( { ArrayTupleStatus => \my @tuple_status } );
		  if($tuples && $rows == $ceti) {
		      Log3 $hash->{NAME}, 4, "DbLog $name -> $rows of $ceti events inserted into table history".($usepkh?" using PK on columns $pkh":"") if($vb4show);
		  } else {
		      $error = "Failed to insert events into history. See logfile";
		      for my $tuple (0..$#row_array) {
			      my $status = $tuple_status[$tuple];
				  $status = 0 if($status eq "0E0");
				  next if($status);         # $status ist "1" wenn insert ok
				  Log3 $hash->{NAME}, 3, "DbLog $name -> Failed to insert into history - TS: $timestamp[$tuple], Device: $device[$tuple], Event: $event[$tuple]" if($vb4show);
			  }
		  }
      }
  };
  if ($@) {
      Log3 $hash->{NAME}, 2, "DbLog $name -> Error table history - $@";
	  $errorh = $@;
      eval {$dbh->rollback() if(!$dbh->{AutoCommit});}; # issue Turning on AutoCommit failed
	  if ($@) {
          Log3($name, 2, "DbLog $name -> Error rollback history - $@");
      }
  } else {
      eval {$dbh->commit() if(!$dbh->{AutoCommit});};   # issue Turning on AutoCommit failed
	  if ($@) {
          Log3($name, 2, "DbLog $name -> Error commit history - $@");
      }
  }

  # update or insert current
  eval {$dbh->begin_work();};  # issue:  begin_work failed: Turning off AutoCommit failed
  if ($@) {
      Log3($name, 2, "DbLog $name -> Error start transaction for history - $@");
  }
  eval {
      if (lc($DbLogType) =~ m(current) ) {
          ($tuples, $rows) = $sth_uc->execute_array( { ArrayTupleStatus => \my @tuple_status } );
		  if($tuples && $rows == $ceti) {
		      Log3 $hash->{NAME}, 4, "DbLog $name -> $rows of $ceti events updated in table current".($usepkc?" using PK on columns $pkc":"");
		  } elsif ($tuples && $rows >= $ceti) {
		      Log3 $hash->{NAME}, 4, "DbLog $name -> $ceti events inserted or replaced in table current".($usepkc?" using PK on columns $pkc":"");
		  } else {
		      $doins = 1;
			  $ceti = 0;
			  for my $tuple (0..$#device) {
			      my $status = $tuple_status[$tuple];
				  $status = 0 if($status eq "0E0");
				  next if($status);         # $status ist "1" wenn update ok
				  $ceti++;
				  Log3 $hash->{NAME}, 4, "DbLog $name -> Failed to update in current, try to insert: TS: $timestamp[$tuple], Device: $device[$tuple], Reading: $reading[$tuple], Status = $status" if($vb4show);
				  push(@timestamp_cur, "$timestamp[$tuple]"); 
	              push(@device_cur, "$device[$tuple]");   
	              push(@type_cur, "$type[$tuple]");  
	              push(@event_cur, "$event[$tuple]");  
	              push(@reading_cur, "$reading[$tuple]"); 
	              push(@value_cur, "$value[$tuple]"); 
	              push(@unit_cur, "$unit[$tuple]");
		      }
		  }
		  
		  if ($doins) {
		      # events die nicht in Tabelle current updated wurden, werden in current neu eingefügt
		      $sth_ic->bind_param_array(1, [@timestamp_cur]);
              $sth_ic->bind_param_array(2, [@device_cur]);
              $sth_ic->bind_param_array(3, [@type_cur]);
              $sth_ic->bind_param_array(4, [@event_cur]);
              $sth_ic->bind_param_array(5, [@reading_cur]);
              $sth_ic->bind_param_array(6, [@value_cur]);
              $sth_ic->bind_param_array(7, [@unit_cur]);
              
			  ($tuples, $rows) = $sth_ic->execute_array( { ArrayTupleStatus => \my @tuple_status } );
			  
			  if($tuples && $rows == $ceti) {
		          Log3 $hash->{NAME}, 4, "DbLog $name -> $rows of $ceti events inserted into table current".($usepkc?" using PK on columns $pkc":"") if($vb4show);
		      } else {
		          $error = "Failed to insert events into history. See logfile";
				  for my $tuple (0..$#device_cur) {
			          my $status = $tuple_status[$tuple];
				      $status = 0 if($status eq "0E0");
				      next if($status);         # $status ist "1" wenn insert ok
				      Log3 $hash->{NAME}, 3, "DbLog $name -> Failed to insert into current - TS: $timestamp[$tuple], Device: $device_cur[$tuple], Reading: $reading_cur[$tuple], Status = $status" if($vb4show);
				  }
		      }
          }

	  }
  };

  if ($@) {
      Log3 $hash->{NAME}, 2, "DbLog $name -> Error table current - $@";
	  $errorc = $@;
      eval {$dbh->rollback() if(!$dbh->{AutoCommit});}; # issue Turning on AutoCommit failed
	  if ($@) {
          Log3($name, 2, "DbLog $name -> Error rollback current - $@");
      }
  } else {
      eval {$dbh->commit() if(!$dbh->{AutoCommit});}; # issue Turning on AutoCommit failed
	  if ($@) {
          Log3($name, 2, "DbLog $name -> Error commit current - $@");
      }
  }

  if ($errorh || $errorc) {
      $error = $errorh.", ".$errorc;
  }
  $dbh->{RaiseError} = 0; 
  $dbh->{PrintError} = 1;

return $error;
}

#################################################################################################
#
# MemCache auswerten und Schreibroutine asynchron und non-blocking aufrufen
#
#################################################################################################
sub DbLog_execmemcache ($) {
  my ($hash) = @_;
  my $name       = $hash->{NAME}; 
  my $syncival   = AttrVal($name, "syncInterval", 30);
  my $clim       = AttrVal($name, "cacheLimit", 500);
  my $async      = AttrVal($name, "asyncMode", undef);
  my $ce         = AttrVal($name, "cacheEvents", 0);
  my $timeout    = AttrVal($name, "timeout", 1800);
  my $dbconn     = $hash->{dbconn};
  my $dbuser     = $hash->{dbuser};
  my $dbpassword = $attr{"sec$name"}{secret};
  my $state      = "connected";
  my $error      = 0;  
  my (@row_array,$memcount,$dbh);
  
  RemoveInternalTimer($hash, "DbLog_execmemcache");
	
  if($init_done != 1) {
      InternalTimer(gettimeofday()+5, "DbLog_execmemcache", $hash, 0);
	  return;
  }
  
  # return wenn "reopen" mit Zeitangabe läuft, oder kein asynchromer Mode oder wenn disabled
  if(!$async || IsDisabled($name) || $hash->{HELPER}{REOPEN_RUNS}) {
	  return;
  }
  
  # tote PID löschen
  if($hash->{HELPER}{RUNNING_PID} && $hash->{HELPER}{RUNNING_PID}{pid} =~ m/DEAD/) {
      delete $hash->{HELPER}{RUNNING_PID};
  }
  
  # nur Verbindungstest, DbLog_PushAsync hat eigene Verbindungsroutine
  eval {
    $dbh = DBI->connect("dbi:$dbconn", $dbuser, $dbpassword, { PrintError => 0, RaiseError => 1 });
  }; 
  
  if ($@) {
      Log3($name, 2, "DbLog $name: Error DBLog_execmemcache - $@");
	  $error = $@;
  } else {
      # Testverbindung abbauen
      $dbh->disconnect(); 
	  
	  $memcount = $hash->{cache}{memcache}?scalar(keys%{$hash->{cache}{memcache}}):0;
      if($ce == 2) {
          readingsSingleUpdate($hash, "CacheUsage", $memcount, 1);
      } else {
	      readingsSingleUpdate($hash, 'CacheUsage', $memcount, 0);
      }
	
	  if($memcount && !$hash->{HELPER}{RUNNING_PID}) {		
	      Log3 $name, 5, "DbLog $name -> ################################################################";
          Log3 $name, 5, "DbLog $name -> ###              New database processing cycle               ###";
          Log3 $name, 5, "DbLog $name -> ################################################################";
	      Log3 $hash->{NAME}, 5, "DbLog $name -> MemCache contains $memcount entries to process";
		
		  
		  foreach my $key (sort(keys%{$hash->{cache}{memcache}})) {
		      Log3 $hash->{NAME}, 5, "DbLog $name -> MemCache contains: $hash->{cache}{memcache}{$key}";
			  push(@row_array, delete($hash->{cache}{memcache}{$key})); 
		  }

		  my $rowlist = join('§', @row_array);
		  $rowlist = encode_base64($rowlist,"");
		  $hash->{HELPER}{RUNNING_PID} = BlockingCall (
		                                     "DbLog_PushAsync", 
		                                     "$name|$rowlist", 
					                         "DbLog_PushAsyncDone", 
									         $timeout, 
									         "DbLog_PushAsyncAborted", 
									         $hash );

          Log3 $hash->{NAME}, 5, "DbLog $name -> DbLog_PushAsync called with timeout: $timeout";
      } else {
	      if($hash->{HELPER}{RUNNING_PID}) {
		      $error = "Commit already running - resync at NextSync";
		  }
	  }
  }
  
  # $memcount = scalar(keys%{$hash->{cache}{memcache}});
  
  my $nextsync = gettimeofday()+$syncival;
  my $nsdt     = FmtDateTime($nextsync);
	  
  if(AttrVal($name, "syncEvents", undef)) {
      readingsSingleUpdate($hash, "NextSync", $nsdt. " or if CacheUsage ".$clim." reached", 1); 
  } else {
      readingsSingleUpdate($hash, "NextSync", $nsdt. " or if CacheUsage ".$clim." reached", 0); 
  }
  
  if($error) {
      readingsSingleUpdate($hash, "state", $error, 1);
  } else {
      readingsSingleUpdate($hash, "state", $state, 0);
  }
  
  InternalTimer($nextsync, "DbLog_execmemcache", $hash, 0);

return;
}

#################################################################################################
#
# Schreibroutine Einfügen Werte in DB asynchron non-blocking
#
#################################################################################################
sub DbLog_PushAsync(@) {
  my ($string) = @_;
  my ($name,$rowlist) = split("\\|", $string);
  my $hash        = $defs{$name};
  my $dbconn      = $hash->{dbconn};
  my $dbuser      = $hash->{dbuser};
  my $dbpassword  = $attr{"sec$name"}{secret};
  my $DbLogType   = AttrVal($name, "DbLogType", "History");
  my $errorh      = 0;
  my $errorc      = 0;
  my $error       = 0;
  my $doins       = 0;  # Hilfsvariable, wenn "1" sollen inserts in Tabelle current erfolgen (updates schlugen fehl) 
  my $dbh;
  my $rowlback    = 0;  # Eventliste für Rückgabe wenn Fehler
  
  Log3 ($name, 5, "DbLog $name -> Start DbLog_PushAsync");
  
  # Background-Startzeit
  my $bst = [gettimeofday];
  
  eval {$dbh = DBI->connect("dbi:$dbconn", $dbuser, $dbpassword, { PrintError => 0, RaiseError => 1 });};
  
  if ($@) {
      $error = encode_base64($@,"");
      Log3 ($name, 2, "DbLog $name - Error: $@");
      Log3 ($name, 5, "DbLog $name -> DbLog_PushAsync finished");
      return "$name|$error|0|$rowlist";
  }
  
  # check ob PK verwendet wird, @usepkx?Anzahl der Felder im PK:0 wenn kein PK, $pkx?Namen der Felder:none wenn kein PK 
  my ($usepkh,$usepkc,$pkh,$pkc) = checkUsePK($hash,$dbh);
  
  my $rowldec = decode_base64($rowlist);
  my @row_array = split('§', $rowldec);
  
  my (@timestamp,@device,@type,@event,@reading,@value,@unit);
  my (@timestamp_cur,@device_cur,@type_cur,@event_cur,@reading_cur,@value_cur,@unit_cur);
  my ($sth_ih,$sth_ic,$sth_uc);
  no warnings 'uninitialized';
  
  my $ceti = $#row_array+1;
  
  foreach my $row (@row_array) {
      my @a = split("\\|",$row);
	  push(@timestamp, "$a[0]"); 
	  push(@device, "$a[1]");   
	  push(@type, "$a[2]");  
	  push(@event, "$a[3]");  
	  push(@reading, "$a[4]"); 
	  push(@value, "$a[5]"); 
	  push(@unit, "$a[6]"); 
	  Log3 $hash->{NAME}, 5, "DbLog $name -> processing event Timestamp: $a[0], Device: $a[1], Type: $a[2], Event: $a[3], Reading: $a[4], Value: $a[5], Unit: $a[6]";
  }	  
  use warnings;
	
  if (lc($DbLogType) =~ m(history)) {
      # insert history mit/ohne primary key
	  if ($usepkh && $hash->{DBMODEL} eq 'MYSQL') {
	      eval { $sth_ih = $dbh->prepare("INSERT IGNORE INTO history (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)"); };
	  } elsif ($usepkh && $hash->{DBMODEL} eq 'SQLITE') {
	      eval { $sth_ih = $dbh->prepare("INSERT OR IGNORE INTO history (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)"); };
	  } elsif ($usepkh && $hash->{DBMODEL} eq 'POSTGRESQL') {
	      eval { $sth_ih = $dbh->prepare("INSERT INTO history (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?) ON CONFLICT DO NOTHING"); };
	  } else {
	      # old behavior
	      eval { $sth_ih = $dbh->prepare("INSERT INTO history (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)"); };
	  }
	  if ($@) {
	      # Eventliste zurückgeben wenn z.B. disk I/O error bei SQLITE
          $error = encode_base64($@,"");
          Log3 ($name, 2, "DbLog $name - Error: $@");
          Log3 ($name, 5, "DbLog $name -> DbLog_PushAsync finished");
		  $dbh->disconnect();
          return "$name|$error|0|$rowlist";
      }
	  $sth_ih->bind_param_array(1, [@timestamp]);
      $sth_ih->bind_param_array(2, [@device]);
      $sth_ih->bind_param_array(3, [@type]);
      $sth_ih->bind_param_array(4, [@event]);
      $sth_ih->bind_param_array(5, [@reading]);
      $sth_ih->bind_param_array(6, [@value]);
      $sth_ih->bind_param_array(7, [@unit]);
  }
  
  if (lc($DbLogType) =~ m(current) ) {
      # insert current mit/ohne primary key, insert-values für current werden generiert
	  if ($usepkc && $hash->{DBMODEL} eq 'MYSQL') {
          eval { $sth_ic = $dbh->prepare("INSERT IGNORE INTO current (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)"); };	  
	  } elsif ($usepkc && $hash->{DBMODEL} eq 'SQLITE') {
	      eval { $sth_ic = $dbh->prepare("INSERT OR IGNORE INTO current (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)"); };
	  } elsif ($usepkc && $hash->{DBMODEL} eq 'POSTGRESQL') {
	      eval { $sth_ic = $dbh->prepare("INSERT INTO current (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?) ON CONFLICT DO NOTHING"); };
	  } else {
	      # old behavior
	      eval { $sth_ic = $dbh->prepare("INSERT INTO current (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)"); };
	  }
	  if ($@) {
	      # Eventliste zurückgeben wenn z.B. Disk I/O error bei SQLITE
          $error = encode_base64($@,"");
          Log3 ($name, 2, "DbLog $name - Error: $@");
          Log3 ($name, 5, "DbLog $name -> DbLog_PushAsync finished");
		  $dbh->disconnect();
          return "$name|$error|0|$rowlist";
      }
	  if ($usepkc && $hash->{DBMODEL} eq 'MYSQL') {
	      # update current (mit PK), insert-values für current wird generiert
		  $sth_uc = $dbh->prepare("REPLACE INTO current (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)");
	      $sth_uc->bind_param_array(1, [@timestamp]);
          $sth_uc->bind_param_array(2, [@device]);
          $sth_uc->bind_param_array(3, [@type]);
          $sth_uc->bind_param_array(4, [@event]);
		  $sth_uc->bind_param_array(5, [@reading]);
          $sth_uc->bind_param_array(6, [@value]);
          $sth_uc->bind_param_array(7, [@unit]);  
	  } elsif ($usepkc && $hash->{DBMODEL} eq 'SQLITE') {  
	      # update current (mit PK), insert-values für current wird generiert
		  $sth_uc = $dbh->prepare("INSERT OR REPLACE INTO current (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?)");
	      $sth_uc->bind_param_array(1, [@timestamp]);
          $sth_uc->bind_param_array(2, [@device]);
          $sth_uc->bind_param_array(3, [@type]);
          $sth_uc->bind_param_array(4, [@event]);
		  $sth_uc->bind_param_array(5, [@reading]);
          $sth_uc->bind_param_array(6, [@value]);
          $sth_uc->bind_param_array(7, [@unit]);
	  } elsif ($usepkc && $hash->{DBMODEL} eq 'POSTGRESQL') {  
	      # update current (mit PK), insert-values für current wird generiert
		  $sth_uc = $dbh->prepare("INSERT INTO current (TIMESTAMP, DEVICE, TYPE, EVENT, READING, VALUE, UNIT) VALUES (?,?,?,?,?,?,?) ON CONFLICT ($pkc) 
		                           DO UPDATE SET TIMESTAMP=EXCLUDED.TIMESTAMP, DEVICE=EXCLUDED.DEVICE, TYPE=EXCLUDED.TYPE, EVENT=EXCLUDED.EVENT, READING=EXCLUDED.READING, 
								   VALUE=EXCLUDED.VALUE, UNIT=EXCLUDED.UNIT");
	      $sth_uc->bind_param_array(1, [@timestamp]);
          $sth_uc->bind_param_array(2, [@device]);
          $sth_uc->bind_param_array(3, [@type]);
          $sth_uc->bind_param_array(4, [@event]);
		  $sth_uc->bind_param_array(5, [@reading]);
          $sth_uc->bind_param_array(6, [@value]);
          $sth_uc->bind_param_array(7, [@unit]);
	  } else {	  
	      # update current (ohne PK), insert-values für current wird generiert
	      $sth_uc = $dbh->prepare("UPDATE current SET TIMESTAMP=?, TYPE=?, EVENT=?, VALUE=?, UNIT=? WHERE (DEVICE=?) AND (READING=?)");
	      $sth_uc->bind_param_array(1, [@timestamp]);
          $sth_uc->bind_param_array(2, [@type]);
          $sth_uc->bind_param_array(3, [@event]);
          $sth_uc->bind_param_array(4, [@value]);
          $sth_uc->bind_param_array(5, [@unit]);
          $sth_uc->bind_param_array(6, [@device]);
          $sth_uc->bind_param_array(7, [@reading]);
	  }
  }

  # SQL-Startzeit
  my $st = [gettimeofday];
  
  my ($tuples, $rows);
 
  # insert into history
  eval {$dbh->begin_work();};  # issue:  begin_work failed: Turning off AutoCommit failed
  if ($@) {
      Log3($name, 2, "DbLog $name -> Error start transaction for history - $@");
  }
  eval {
      if (lc($DbLogType) =~ m(history) ) {
          ($tuples, $rows) = $sth_ih->execute_array( { ArrayTupleStatus => \my @tuple_status } );
		  if($tuples && $rows == $ceti) {
		      Log3 $hash->{NAME}, 5, "DbLog $name -> $rows of $ceti events inserted into table history".($usepkh?" using PK on columns $pkh":"");
		  } else {
		      $error = "Failed to insert events into history. See logfile";
		      for my $tuple (0..$#row_array) {
			      my $status = $tuple_status[$tuple];
				  $status = 0 if($status eq "0E0");
				  next if($status);         # $status ist "1" wenn insert ok
				  Log3 $hash->{NAME}, 3, "DbLog $name -> Failed to insert into history - TS: $timestamp[$tuple], Device: $device[$tuple], Event: $event[$tuple]";
			  }
		  }
      }
  };
  
  if ($@) {
      Log3 $hash->{NAME}, 2, "DbLog $name -> Error table history - $@";
	  $errorh = $@;
      eval {$dbh->rollback() if(!$dbh->{AutoCommit});};  # issue Turning on AutoCommit failed
	  if ($@) {
          Log3($name, 2, "DbLog $name -> Error rollback history - $@");
      } 
      $rowlback = $rowlist;	
  } else {
      eval {$dbh->commit() if(!$dbh->{AutoCommit});};    # issue Turning on AutoCommit failed
      if ($@) {
          Log3($name, 2, "DbLog $name -> Error commit history - $@");
      }
  }
  
  # update or insert current
  eval {$dbh->begin_work();};  # issue:  begin_work failed: Turning off AutoCommit failed
  if ($@) {
      Log3($name, 2, "DbLog $name -> Error start transaction for current - $@");
  }
  eval {
	  if (lc($DbLogType) =~ m(current) ) {
          ($tuples, $rows) = $sth_uc->execute_array( { ArrayTupleStatus => \my @tuple_status } );
		  if($tuples && $rows == $ceti) {
		      Log3 $hash->{NAME}, 5, "DbLog $name -> $rows of $ceti events updated in table current".($usepkc?" using PK on columns $pkc":"");
		  } elsif ($tuples && $rows >= $ceti) {
		      Log3 $hash->{NAME}, 5, "DbLog $name -> $ceti events inserted or replaced in table current".($usepkc?" using PK on columns $pkc":"");
		  } else {
		      $doins = 1;
			  $ceti = 0;
			  for my $tuple (0..$#device) {
			      my $status = $tuple_status[$tuple];
			      $status = 0 if($status eq "0E0");
			      next if($status);         # $status ist "1" wenn update ok
			      $ceti++;
			      Log3 $hash->{NAME}, 5, "DbLog $name -> Failed to update in current, try to insert - TS: $timestamp[$tuple], Device: $device[$tuple], Reading: $reading[$tuple], Status = $status";
			      push(@timestamp_cur, "$timestamp[$tuple]"); 
	              push(@device_cur, "$device[$tuple]");   
	              push(@type_cur, "$type[$tuple]");  
	              push(@event_cur, "$event[$tuple]");  
	              push(@reading_cur, "$reading[$tuple]"); 
	              push(@value_cur, "$value[$tuple]"); 
	              push(@unit_cur, "$unit[$tuple]");
		      }
		  }
		  
		  if ($doins) {
		      # events die nicht in Tabelle current updated wurden, werden in current neu eingefügt
		      $sth_ic->bind_param_array(1, [@timestamp_cur]);
              $sth_ic->bind_param_array(2, [@device_cur]);
              $sth_ic->bind_param_array(3, [@type_cur]);
              $sth_ic->bind_param_array(4, [@event_cur]);
              $sth_ic->bind_param_array(5, [@reading_cur]);
              $sth_ic->bind_param_array(6, [@value_cur]);
              $sth_ic->bind_param_array(7, [@unit_cur]);
              
			  ($tuples, $rows) = $sth_ic->execute_array( { ArrayTupleStatus => \my @tuple_status } );
			  if($tuples && $rows == $ceti) {
		          Log3 $hash->{NAME}, 5, "DbLog $name -> $rows of $ceti events inserted into table current".($usepkc?" using PK on columns $pkc":"");
		      } else {
		          $error = "Failed to insert events into history. See logfile";
			      for my $tuple (0..$#device_cur) {
			          my $status = $tuple_status[$tuple];
			          $status = 0 if($status eq "0E0");
			          next if($status);         # $status ist "1" wenn insert ok
			          Log3 $hash->{NAME}, 2, "DbLog $name -> Failed to insert into current - TS: $timestamp[$tuple], Device: $device_cur[$tuple], Reading: $reading_cur[$tuple], Status = $status";
			      }
		      }
          }
	  }
  };

  if ($@) {
      Log3 $hash->{NAME}, 2, "DbLog $name -> Error table current - $@";
	  $errorc = $@;
      eval {$dbh->rollback() if(!$dbh->{AutoCommit});};  # issue Turning on AutoCommit failed
	  if ($@) {
          Log3($name, 2, "DbLog $name -> Error rollback current - $@");
      } 
  } else {
      eval {$dbh->commit() if(!$dbh->{AutoCommit});};    # issue Turning on AutoCommit failed
      if ($@) {
          Log3($name, 2, "DbLog $name -> Error commit current - $@");
      }
  }
  
  $dbh->disconnect();
  
  # SQL-Laufzeit ermitteln
  my $rt = tv_interval($st);

  if ($errorh || $errorc) {
      my $err = $errorh.", ".$errorc;
	  $error = encode_base64($err,"");
  }
  
  Log3 ($name, 5, "DbLog $name -> DbLog_PushAsync finished");

  # Background-Laufzeit ermitteln
  my $brt = tv_interval($bst);

  $rt = $rt.",".$brt;
 
return "$name|$error|$rt|$rowlback";
}

#############################################################################################
#         Auswertung non-blocking asynchron DbLog_PushAsync
#############################################################################################
sub DbLog_PushAsyncDone ($) {
 my ($string)   = @_;
 my @a          = split("\\|",$string);
 my $name       = $a[0];
 my $hash       = $defs{$name};
 my $error      = $a[1]?decode_base64($a[1]):0;
 my $bt         = $a[2];
 my $rowlist    = $a[3];
 my $asyncmode  = AttrVal($name, "asyncMode", undef);
 my $state      = "connected";
 my $memcount;

 if($rowlist) {
     $rowlist = decode_base64($rowlist);
     my @row_array = split('§', $rowlist);
	 
	 #one Transaction
     eval { 
	   foreach my $row (@row_array) {
	       # Cache & CacheIndex für Events zum asynchronen Schreiben in DB
		   $hash->{cache}{index}++;
		   my $index = $hash->{cache}{index};
		   $hash->{cache}{memcache}{$index} = $row;
	   }
	   $memcount = scalar(keys%{$hash->{cache}{memcache}});
	 };
  }
	  
 Log3 ($name, 5, "DbLog $name -> Start DbLog_PushAsyncDone");
 $state = "disabled" if(IsDisabled($name));
 
 $memcount = $hash->{cache}{memcache}?scalar(keys%{$hash->{cache}{memcache}}):0;
 readingsSingleUpdate($hash, 'CacheUsage', $memcount, 0);
 
 if(AttrVal($name, "showproctime", undef) && $bt) {
     my ($rt,$brt) = split(",", $bt);
     readingsBeginUpdate($hash);
     readingsBulkUpdate($hash, "background_processing_time", sprintf("%.4f",$brt));     
     readingsBulkUpdate($hash, "sql_processing_time", sprintf("%.4f",$rt));
     readingsEndUpdate($hash, 1);
 }
 
  if($error) {
      readingsSingleUpdate($hash, "state", $error, 1);
  } else {
      readingsSingleUpdate($hash, "state", $state, 0);
  } 
 
 if(!$asyncmode) {
     delete($defs{$name}{READINGS}{NextSync});
	 delete($defs{$name}{READINGS}{background_processing_time});
	 delete($defs{$name}{READINGS}{sql_processing_time});
	 delete($defs{$name}{READINGS}{CacheUsage});
 }
 
 delete $hash->{HELPER}{RUNNING_PID};
 Log3 ($name, 5, "DbLog $name -> DbLog_PushAsyncDone finished");
 
return;
 
}
 
#############################################################################################
#           Abbruchroutine Timeout non-blocking asynchron DbLog_PushAsync
#############################################################################################
sub DbLog_PushAsyncAborted($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  
  Log3 ($name, 2, "DbLog $name -> $hash->{HELPER}{RUNNING_PID}{fn} timed out");
  readingsSingleUpdate($hash, "state", "Database access timeout", 1);
  delete $hash->{HELPER}{RUNNING_PID};
}


################################################################
#
# zerlegt uebergebenes FHEM-Datum in die einzelnen Bestandteile
# und fuegt noch Defaultwerte ein
# uebergebenes SQL-Format: YYYY-MM-DD HH24:MI:SS
#
################################################################
sub DbLog_explode_datetime($%) {
  my ($t, %def) = @_;
  my %retv;

  my (@datetime, @date, @time);
  @datetime = split(" ", $t); #Datum und Zeit auftrennen
  @date = split("-", $datetime[0]);
  @time = split(":", $datetime[1]) if ($datetime[1]);
  if ($date[0]) {$retv{year}  = $date[0];} else {$retv{year}  = $def{year};}
  if ($date[1]) {$retv{month} = $date[1];} else {$retv{month} = $def{month};}
  if ($date[2]) {$retv{day}   = $date[2];} else {$retv{day}   = $def{day};}
  if ($time[0]) {$retv{hour}  = $time[0];} else {$retv{hour}  = $def{hour};}
  if ($time[1]) {$retv{minute}= $time[1];} else {$retv{minute}= $def{minute};}
  if ($time[2]) {$retv{second}= $time[2];} else {$retv{second}= $def{second};}

  $retv{datetime}=DbLog_implode_datetime($retv{year}, $retv{month}, $retv{day}, $retv{hour}, $retv{minute}, $retv{second});

  #Log 1, Dumper(%retv);
  return %retv
}

sub DbLog_implode_datetime($$$$$$) {
  my ($year, $month, $day, $hour, $minute, $second) = @_;
  my $retv = $year."-".$month."-".$day." ".$hour.":".$minute.":".$second;

  return $retv;
}

################################################################
#
#                  Verbindungen zur DB aufbauen
#
################################################################
sub _DbLog_readCfg($){
  my ($hash)= @_;
  my $name = $hash->{NAME};

  my $configfilename= $hash->{CONFIGURATION};
  my %dbconfig; 
  my $ret;

# use generic fileRead to get configuration data
  my ($err, @config) = FileRead($configfilename);
  return $err if($err);

  eval join("\n", @config);

  $hash->{dbconn}     = $dbconfig{connection};
  $hash->{dbuser}     = $dbconfig{user};
  $attr{"sec$name"}{secret} = $dbconfig{password};

  #check the database model
  if($hash->{dbconn} =~ m/pg:/i) {
    $hash->{DBMODEL}="POSTGRESQL";
  } elsif ($hash->{dbconn} =~ m/mysql:/i) {
    $hash->{DBMODEL}="MYSQL";
  } elsif ($hash->{dbconn} =~ m/oracle:/i) {
    $hash->{DBMODEL}="ORACLE";
  } elsif ($hash->{dbconn} =~ m/sqlite:/i) {
    $hash->{DBMODEL}="SQLITE";
  } else {
    $hash->{DBMODEL}="unknown";
    Log3 $hash->{NAME}, 3, "Unknown dbmodel type in configuration file $configfilename.";
    Log3 $hash->{NAME}, 3, "Only Mysql, Postgresql, Oracle, SQLite are fully supported.";
    Log3 $hash->{NAME}, 3, "It may cause SQL-Erros during generating plots.";
  }
	return;
}

sub DbLog_ConnectPush($) {
  # own $dbhp only for synchronous logging
  my ($hash)= @_;
  my $name = $hash->{NAME};
  my $dbconn     = $hash->{dbconn};
  my $dbuser     = $hash->{dbuser};
  my $dbpassword = $attr{"sec$name"}{secret};
  
  Log3 $hash->{NAME}, 3, "DbLog $name: Creating Push-Handle to database $dbconn with user $dbuser";
  my $dbhp = DBI->connect("dbi:$dbconn", $dbuser, $dbpassword, { PrintError => 0 });
  
  if(!$dbhp) {
    RemoveInternalTimer($hash, "DbLog_ConnectPush");
    Log3 $hash->{NAME}, 4, 'DbLog $name: Trying to connect to database';
    readingsSingleUpdate($hash, 'state', 'disconnected', 1);
    InternalTimer(time+5, 'DbLog_ConnectPush', $hash, 0);
    Log3 $hash->{NAME}, 4, 'Waiting for database connection';
    return 0;
  }

  Log3 $hash->{NAME}, 3, "DbLog $name: Push-Handle to db $dbconn created";
  readingsSingleUpdate($hash, 'state', 'connected', 1);

  $hash->{DBHP}= $dbhp;
  
  if ($hash->{DBMODEL} eq "SQLITE") {
    $dbhp->do("PRAGMA temp_store=MEMORY");
    $dbhp->do("PRAGMA synchronous=NORMAL");
    $dbhp->do("PRAGMA journal_mode=WAL");
    $dbhp->do("PRAGMA cache_size=4000");
  }
 
  return 1;
}

sub DbLog_ConnectNewDBH($) {
  # new dbh for every use (except DbLog_Push)
  my ($hash)= @_;
  my $name = $hash->{NAME};
  my $dbconn     = $hash->{dbconn};
  my $dbuser     = $hash->{dbuser};
  my $dbpassword = $attr{"sec$name"}{secret};
  my $dbh;
 
  eval { $dbh = DBI->connect("dbi:$dbconn", $dbuser, $dbpassword, { PrintError => 0 }); };
  
  if($@) {
    Log3($name, 2, "DbLog $name: - $@");
  }
  
  if($dbh) {
      return $dbh;
  } else {
      return 0;
  }
}

##########################################################################
#
# Prozedur zum Ausfuehren von SQL-Statements durch externe Module
#
# param1: DbLog-hash
# param2: SQL-Statement
##########################################################################
sub DbLog_ExecSQL($$)
{
  my ($hash,$sql)= @_;
  Log3 $hash->{NAME}, 4, "Executing $sql";
  my $dbh = DbLog_ConnectNewDBH($hash);
  return if(!$dbh);
  my $sth = DbLog_ExecSQL1($hash,$dbh,$sql);
  if(!$sth) {
    #retry
    $dbh->disconnect();
    $dbh = DbLog_ConnectNewDBH($hash);
    return if(!$dbh);
    $sth = DbLog_ExecSQL1($hash,$dbh,$sql);
    if(!$sth) {
      Log3 $hash->{NAME}, 2, "DBLog retry failed.";
      return 0;
    }
    Log3 $hash->{NAME}, 2, "DBLog retry ok.";
  }
  return $sth;
}

sub DbLog_ExecSQL1($$$)
{
  my ($hash,$dbh,$sql)= @_;

  my $sth = $dbh->do($sql);
  if(!$sth) {
    Log3 $hash->{NAME}, 2, "DBLog error: " . $DBI::errstr;
    return 0;
  }
  return $sth;
}

################################################################
#
# GET Funktion
# wird zb. zur Generierung der Plots implizit aufgerufen
# infile : [-|current|history]
# outfile: [-|ALL|INT|WEBCHART]
#
################################################################
sub
DbLog_Get($@)
{
  my ($hash, @a) = @_;
  my $name = $hash->{NAME};
  my $dbh;
  
  $dbh = DbLog_ConnectNewDBH($hash);
  return if(!$dbh); 
  
  return dbReadings($hash,@a) if $a[1] =~ m/^Readings/;

  return "Usage: get $a[0] <in> <out> <from> <to> <column_spec>...\n".
     "  where column_spec is <device>:<reading>:<default>:<fn>\n" .
     "  see the #DbLog entries in the .gplot files\n" .
     "  <in> is not used, only for compatibility for FileLog, please use - \n" .
     "  <out> is a prefix, - means stdout\n"
    if(int(@a) < 5);
  shift @a;
  my $inf  = lc(shift @a);
  my $outf = lc(shift @a);
  my $from = shift @a;
  my $to   = shift @a; # Now @a contains the list of column_specs
  my ($internal, @fld);

  if($inf eq "-") {
    $inf = "history";
  }

  if($outf eq "int" && $inf eq "current") {
    $inf = "history";
    Log3 $hash->{NAME}, 3, "Defining DbLog SVG-Plots with :CURRENT is deprecated. Please define DbLog SVG-Plots with :HISTORY instead of :CURRENT. (define <mySVG> SVG <DbLogDev>:<gplotfile>:HISTORY)";
  }

  if($outf eq "int") {
    $outf = "-";
    $internal = 1;
  } elsif($outf eq "array"){

  } elsif(lc($outf) eq "webchart") {
    # redirect the get request to the chartQuery function
    return chartQuery($hash, @_);
  }

  my @readings = ();
  my (%sqlspec, %from_datetime, %to_datetime);

  #uebergebenen Timestamp anpassen
  #moegliche Formate: YYYY | YYYY-MM | YYYY-MM-DD | YYYY-MM-DD_HH24
  $from =~ s/_/\ /g;
  $to   =~ s/_/\ /g;
  %from_datetime = DbLog_explode_datetime($from, DbLog_explode_datetime("2000-01-01 00:00:00", ()));
  %to_datetime   = DbLog_explode_datetime($to, DbLog_explode_datetime("2099-01-01 00:00:00", ()));
  $from = $from_datetime{datetime};
  $to = $to_datetime{datetime};


  my ($retval,$retvaldummy,$hour,$sql_timestamp, $sql_device, $sql_reading, $sql_value, $type, $event, $unit) = "";
  my @ReturnArray;
  my $writeout = 0;
  my (@min, @max, @sum, @cnt, @lastv, @lastd, @mind, @maxd);
  my (%tstamp, %lasttstamp, $out_tstamp, $out_value, $minval, $maxval, $deltacalc); #fuer delta-h/d Berechnung

  #extract the Device:Reading arguments into @readings array
  for(my $i = 0; $i < int(@a); $i++) {
    @fld = split(":", $a[$i], 5);
    $readings[$i][0] = $fld[0]; # Device
    $readings[$i][1] = $fld[1]; # Reading
    $readings[$i][2] = $fld[2]; # Default
    $readings[$i][3] = $fld[3]; # function
    $readings[$i][4] = $fld[4]; # regexp

    $readings[$i][1] = "%" if(!$readings[$i][1] || length($readings[$i][1])==0); #falls Reading nicht gefuellt setze Joker
  }

  #create new connection for plotfork
  if( $hash->{PID} != $$ ) {
    $dbh->disconnect(); 
    return "Can't connect to database." if(!DbLog_ConnectNewDBH($hash));
  }
  $dbh = DbLog_ConnectNewDBH($hash);
  return if(!$dbh);

  #vorbereiten der DB-Abfrage, DB-Modell-abhaengig
  if ($hash->{DBMODEL} eq "POSTGRESQL") {
    $sqlspec{get_timestamp}  = "TO_CHAR(TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS')";
    $sqlspec{from_timestamp} = "TO_TIMESTAMP('$from', 'YYYY-MM-DD HH24:MI:SS')";
    $sqlspec{to_timestamp}   = "TO_TIMESTAMP('$to', 'YYYY-MM-DD HH24:MI:SS')";
    #$sqlspec{reading_clause} = "(DEVICE || '|' || READING)";
    $sqlspec{order_by_hour}  = "TO_CHAR(TIMESTAMP, 'YYYY-MM-DD HH24')";
    $sqlspec{max_value}      = "MAX(VALUE)";
    $sqlspec{day_before}     = "($sqlspec{from_timestamp} - INTERVAL '1 DAY')";
  } elsif ($hash->{DBMODEL} eq "ORACLE") {
    $sqlspec{get_timestamp}  = "TO_CHAR(TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS')";
    $sqlspec{from_timestamp} = "TO_TIMESTAMP('$from', 'YYYY-MM-DD HH24:MI:SS')";
    $sqlspec{to_timestamp}   = "TO_TIMESTAMP('$to', 'YYYY-MM-DD HH24:MI:SS')";
    $sqlspec{order_by_hour}  = "TO_CHAR(TIMESTAMP, 'YYYY-MM-DD HH24')";
    $sqlspec{max_value}      = "MAX(VALUE)";
    $sqlspec{day_before}     = "DATE_SUB($sqlspec{from_timestamp},INTERVAL 1 DAY)";
  } elsif ($hash->{DBMODEL} eq "MYSQL") {
    $sqlspec{get_timestamp}  = "DATE_FORMAT(TIMESTAMP, '%Y-%m-%d %H:%i:%s')";
    $sqlspec{from_timestamp} = "STR_TO_DATE('$from', '%Y-%m-%d %H:%i:%s')";
    $sqlspec{to_timestamp}   = "STR_TO_DATE('$to', '%Y-%m-%d %H:%i:%s')";
    $sqlspec{order_by_hour}  = "DATE_FORMAT(TIMESTAMP, '%Y-%m-%d %H')";
    $sqlspec{max_value}      = "MAX(CAST(VALUE AS DECIMAL(20,8)))";
    $sqlspec{day_before}     = "DATE_SUB($sqlspec{from_timestamp},INTERVAL 1 DAY)";
  } elsif ($hash->{DBMODEL} eq "SQLITE") {
    $sqlspec{get_timestamp}  = "TIMESTAMP";
    $sqlspec{from_timestamp} = "'$from'";
    $sqlspec{to_timestamp}   = "'$to'";
    $sqlspec{order_by_hour}  = "strftime('%Y-%m-%d %H', TIMESTAMP)";
    $sqlspec{max_value}      = "MAX(VALUE)";
    $sqlspec{day_before}     = "date($sqlspec{from_timestamp},'-1 day')";
  } else {
    $sqlspec{get_timestamp}  = "TIMESTAMP";
    $sqlspec{from_timestamp} = "'$from'";
    $sqlspec{to_timestamp}   = "'$to'";
    $sqlspec{order_by_hour}  = "strftime('%Y-%m-%d %H', TIMESTAMP)";
    $sqlspec{max_value}      = "MAX(VALUE)";
    $sqlspec{day_before}     = "date($sqlspec{from_timestamp},'-1 day')";
  }

  if($outf =~ m/(all|array)/) {
    $sqlspec{all}  = ",TYPE,EVENT,UNIT";
    $sqlspec{all_max}  = ",MAX(TYPE) AS TYPE,MAX(EVENT) AS EVENT,MAX(UNIT) AS UNIT";
  } else {
    $sqlspec{all}  = "";
    $sqlspec{all_max}  = "";
  }

  for(my $i=0; $i<int(@readings); $i++) {
    # ueber alle Readings
    # Variablen initialisieren
    $min[$i]   =  (~0 >> 1);
    $max[$i]   = -(~0 >> 1);
    $sum[$i]   = 0;
    $cnt[$i]   = 0;
    $lastv[$i] = 0;
    $lastd[$i] = "undef";
    $mind[$i]  = "undef";
    $maxd[$i]  = "undef";
    $minval    =  (~0 >> 1);
    $maxval    = -(~0 >> 1);
    $deltacalc = 0;

    if($readings[$i]->[3] && ($readings[$i]->[3] eq "delta-h" || $readings[$i]->[3] eq "delta-d")) {
      $deltacalc = 1;
    }

    my $stm;
    my $stm2;
    my $stmdelta;
    $stm =  "SELECT
                  MAX($sqlspec{get_timestamp}) AS TIMESTAMP,
                  MAX(DEVICE) AS DEVICE,
                  MAX(READING) AS READING,
                  $sqlspec{max_value}
                  $sqlspec{all_max} ";

    $stm .= "FROM current " if($inf eq "current");
    $stm .= "FROM history " if($inf eq "history");

    $stm .= "WHERE 1=1 ";
    
    $stm .= "AND DEVICE  = '".$readings[$i]->[0]."' "   if ($readings[$i]->[0] !~ m(\%));
    $stm .= "AND DEVICE LIKE '".$readings[$i]->[0]."' " if(($readings[$i]->[0] !~ m(^\%$)) && ($readings[$i]->[0] =~ m(\%)));

    $stm .= "AND READING = '".$readings[$i]->[1]."' "    if ($readings[$i]->[1] !~ m(\%));
    $stm .= "AND READING LIKE '".$readings[$i]->[1]."' " if(($readings[$i]->[1] !~ m(^%$)) && ($readings[$i]->[1] =~ m(\%)));

    $stmdelta = $stm;

    $stm .= "AND TIMESTAMP < $sqlspec{from_timestamp} ";
    $stm .= "AND TIMESTAMP > $sqlspec{day_before} ";

    $stm .= "UNION ALL ";

    $stm2 =  "SELECT
                  $sqlspec{get_timestamp},
                  DEVICE,
                  READING,
                  VALUE
                  $sqlspec{all} ";

    $stm2 .= "FROM current " if($inf eq "current");
    $stm2 .= "FROM history " if($inf eq "history");

    $stm2 .= "WHERE 1=1 ";

    $stm2 .= "AND DEVICE  = '".$readings[$i]->[0]."' "   if ($readings[$i]->[0] !~ m(\%));
    $stm2 .= "AND DEVICE LIKE '".$readings[$i]->[0]."' " if(($readings[$i]->[0] !~ m(^\%$)) && ($readings[$i]->[0] =~ m(\%)));

    $stm2 .= "AND READING = '".$readings[$i]->[1]."' "    if ($readings[$i]->[1] !~ m(\%));
    $stm2 .= "AND READING LIKE '".$readings[$i]->[1]."' " if(($readings[$i]->[1] !~ m(^%$)) && ($readings[$i]->[1] =~ m(\%)));

    $stm2 .= "AND TIMESTAMP >= $sqlspec{from_timestamp} ";
    $stm2 .= "AND TIMESTAMP < $sqlspec{to_timestamp} ";
    $stm2 .= "ORDER BY TIMESTAMP";

    if($deltacalc) {
      $stmdelta .= "AND TIMESTAMP >= $sqlspec{from_timestamp} ";
      $stmdelta .= "AND TIMESTAMP < $sqlspec{to_timestamp} ";

      $stmdelta .= "GROUP BY $sqlspec{order_by_hour} " if($deltacalc);
      $stmdelta .= "ORDER BY TIMESTAMP";
      $stm .= $stmdelta;
    } else {
      $stm = $stm2;
    }


    Log3 $hash->{NAME}, 4, "Processing Statement: $stm";

    my $sth= $dbh->prepare($stm) ||
      return "Cannot prepare statement $stm: $DBI::errstr";
    my $rc= $sth->execute() ||
      return "Cannot execute statement $stm: $DBI::errstr";

    if($outf =~ m/(all|array)/) {
      $sth->bind_columns(undef, \$sql_timestamp, \$sql_device, \$sql_reading, \$sql_value, \$type, \$event, \$unit);
    }
    else {
      $sth->bind_columns(undef, \$sql_timestamp, \$sql_device, \$sql_reading, \$sql_value);
    }

    if ($outf =~ m/(all)/) {
      $retval .= "Timestamp: Device, Type, Event, Reading, Value, Unit\n";
      $retval .= "=====================================================\n";
    }

    while($sth->fetch()) {

      ############ Auswerten des 5. Parameters: Regexp ###################
      # die Regexep wird vor der Function ausgewertet und der Wert im Feld
      # Value angepasst.
      ####################################################################
      if($readings[$i]->[4]) {
        #evaluate
        my $val = $sql_value;
        my $ts  = $sql_timestamp;
        eval("$readings[$i]->[4]");
        $sql_value = $val;
        $sql_timestamp = $ts;
        if($@) {Log3 $hash->{NAME}, 3, "DbLog: Error in inline function: <".$readings[$i]->[4].">, Error: $@";}
      }

      if($sql_timestamp lt $from && $deltacalc) {
        if(Scalar::Util::looks_like_number($sql_value)){
          #nur setzen wenn nummerisch
          $minval = $sql_value if($sql_value < $minval);
          $maxval = $sql_value if($sql_value > $maxval);
          $lastv[$i] = $sql_value;
        }
      } else {

        $writeout   = 0;
        $out_value  = "";
        $out_tstamp = "";
        $retvaldummy = "";

        if($readings[$i]->[4]) {
          $out_tstamp = $sql_timestamp;
          $writeout=1 if(!$deltacalc);
        }

        ############ Auswerten des 4. Parameters: function ###################
        if($readings[$i]->[3] && $readings[$i]->[3] eq "int") {
          #nur den integerwert uebernehmen falls zb value=15°C
          $out_value = $1 if($sql_value =~ m/^(\d+).*/o);
          $out_tstamp = $sql_timestamp;
          $writeout=1;

        } elsif ($readings[$i]->[3] && $readings[$i]->[3] =~ m/^int(\d+).*/o) {
          #Uebernehme den Dezimalwert mit den angegebenen Stellen an Nachkommastellen
          $out_value = $1 if($sql_value =~ m/^([-\.\d]+).*/o);
          $out_tstamp = $sql_timestamp;
          $writeout=1;

        } elsif ($readings[$i]->[3] && $readings[$i]->[3] eq "delta-ts" && lc($sql_value) !~ m(ignore)) {
          #Berechung der vergangen Sekunden seit dem letten Logeintrag
          #zb. die Zeit zwischen on/off
          my @a = split("[- :]", $sql_timestamp);
          my $akt_ts = mktime($a[5],$a[4],$a[3],$a[2],$a[1]-1,$a[0]-1900,0,0,-1);
          if($lastd[$i] ne "undef") {
            @a = split("[- :]", $lastd[$i]);
          }
          my $last_ts = mktime($a[5],$a[4],$a[3],$a[2],$a[1]-1,$a[0]-1900,0,0,-1);
          $out_tstamp = $sql_timestamp;
          $out_value = sprintf("%02d", $akt_ts - $last_ts);
          if(lc($sql_value) =~ m(hide)){$writeout=0;} else {$writeout=1;}

        } elsif ($readings[$i]->[3] && $readings[$i]->[3] eq "delta-h") {
          #Berechnung eines Stundenwertes
          %tstamp = DbLog_explode_datetime($sql_timestamp, ());
          if($lastd[$i] eq "undef") {
            %lasttstamp = DbLog_explode_datetime($sql_timestamp, ());
            $lasttstamp{hour} = "00";
          } else {
            %lasttstamp = DbLog_explode_datetime($lastd[$i], ());
          }
          #    04                   01
          #    06                   23
          if("$tstamp{hour}" ne "$lasttstamp{hour}") {
            # Aenderung der stunde, Berechne Delta
            #wenn die Stundendifferenz größer 1 ist muss ein Dummyeintrag erstellt werden
            $retvaldummy = "";
            if(($tstamp{hour}-$lasttstamp{hour}) > 1) {
              for (my $j=$lasttstamp{hour}+1; $j < $tstamp{hour}; $j++) {
                $out_value  = "0";
                $hour = $j;
                $hour = '0'.$j if $j<10;
                $cnt[$i]++;
                $out_tstamp = DbLog_implode_datetime($tstamp{year}, $tstamp{month}, $tstamp{day}, $hour, "30", "00");
                if ($outf =~ m/(all)/) {
                  # Timestamp: Device, Type, Event, Reading, Value, Unit
                  $retvaldummy .= sprintf("%s: %s, %s, %s, %s, %s, %s\n", $out_tstamp, $sql_device, $type, $event, $sql_reading, $out_value, $unit);
              
                } elsif ($outf =~ m/(array)/) {
                  push(@ReturnArray, {"tstamp" => $out_tstamp, "device" => $sql_device, "type" => $type, "event" => $event, "reading" => $sql_reading, "value" => $out_value, "unit" => $unit});
              
                } else {
                  $out_tstamp =~ s/\ /_/g; #needed by generating plots
                  $retvaldummy .= "$out_tstamp $out_value\n";
                }
              }
            }
            if(($tstamp{hour}-$lasttstamp{hour}) < 0) {
              for (my $j=0; $j < $tstamp{hour}; $j++) {
                $out_value  = "0";
                $hour = $j;
                $hour = '0'.$j if $j<10;
                $cnt[$i]++;
                $out_tstamp = DbLog_implode_datetime($tstamp{year}, $tstamp{month}, $tstamp{day}, $hour, "30", "00");
                if ($outf =~ m/(all)/) {
                  # Timestamp: Device, Type, Event, Reading, Value, Unit
                  $retvaldummy .= sprintf("%s: %s, %s, %s, %s, %s, %s\n", $out_tstamp, $sql_device, $type, $event, $sql_reading, $out_value, $unit);
              
                } elsif ($outf =~ m/(array)/) {
                  push(@ReturnArray, {"tstamp" => $out_tstamp, "device" => $sql_device, "type" => $type, "event" => $event, "reading" => $sql_reading, "value" => $out_value, "unit" => $unit});
              
                } else {
                  $out_tstamp =~ s/\ /_/g; #needed by generating plots
                  $retvaldummy .= "$out_tstamp $out_value\n";
                }
              }
            }
            $out_value = sprintf("%g", $maxval - $minval);
            $sum[$i] += $out_value;
            $cnt[$i]++;
            $out_tstamp = DbLog_implode_datetime($lasttstamp{year}, $lasttstamp{month}, $lasttstamp{day}, $lasttstamp{hour}, "30", "00");
            #$minval =  (~0 >> 1);
            $minval = $maxval;
#            $maxval = -(~0 >> 1);
            $writeout=1;
          }
        } elsif ($readings[$i]->[3] && $readings[$i]->[3] eq "delta-d") {
          #Berechnung eines Tageswertes
          %tstamp = DbLog_explode_datetime($sql_timestamp, ());
          if($lastd[$i] eq "undef") {
            %lasttstamp = DbLog_explode_datetime($sql_timestamp, ());
          } else {
            %lasttstamp = DbLog_explode_datetime($lastd[$i], ());
          }
          if("$tstamp{day}" ne "$lasttstamp{day}") {
            # Aenderung des Tages, Berechne Delta
            $out_value = sprintf("%g", $maxval - $minval);
            $sum[$i] += $out_value;
            $cnt[$i]++;
            $out_tstamp = DbLog_implode_datetime($lasttstamp{year}, $lasttstamp{month}, $lasttstamp{day}, "12", "00", "00");
#            $minval =  (~0 >> 1);
            $minval = $maxval;
#            $maxval = -(~0 >> 1);
            $writeout=1;
          }
        } else {
          $out_value = $sql_value;
          $out_tstamp = $sql_timestamp;
          $writeout=1;
        }

        # Wenn Attr SuppressUndef gesetzt ist, dann ausfiltern aller undef-Werte
        $writeout = 0 if (!defined($sql_value) && AttrVal($hash->{NAME}, "suppressUndef", 0));
 
        ###################### Ausgabe ###########################
        if($writeout) {
            if ($outf =~ m/(all)/) {
              # Timestamp: Device, Type, Event, Reading, Value, Unit
              $retval .= sprintf("%s: %s, %s, %s, %s, %s, %s\n", $out_tstamp, $sql_device, $type, $event, $sql_reading, $out_value, $unit);
              $retval .= $retvaldummy;
            
            } elsif ($outf =~ m/(array)/) {
              push(@ReturnArray, {"tstamp" => $out_tstamp, "device" => $sql_device, "type" => $type, "event" => $event, "reading" => $sql_reading, "value" => $out_value, "unit" => $unit});
              
            } else {
              $out_tstamp =~ s/\ /_/g; #needed by generating plots
              $retval .= "$out_tstamp $out_value\n";
              $retval .= $retvaldummy;
            }
        }

        if(Scalar::Util::looks_like_number($sql_value)){
          #nur setzen wenn nummerisch
          if($deltacalc) {
            if(Scalar::Util::looks_like_number($out_value)){
              if($out_value < $min[$i]) {
                $min[$i] = $out_value;
                $mind[$i] = $out_tstamp;
              }
              if($out_value > $max[$i]) {
                $max[$i] = $out_value;
                $maxd[$i] = $out_tstamp;
              }
            }
            $maxval = $sql_value;
          } else {
            if($sql_value < $min[$i]) {
              $min[$i] = $sql_value;
              $mind[$i] = $sql_timestamp;
            }
            if($sql_value > $max[$i]) {
              $max[$i] = $sql_value;
              $maxd[$i] = $sql_timestamp;
            }
            $sum[$i] += $sql_value;
            $minval = $sql_value if($sql_value < $minval);
            $maxval = $sql_value if($sql_value > $maxval);
          }
        } else {
          $min[$i] = 0;
          $max[$i] = 0;
          $sum[$i] = 0;
          $minval  = 0;
          $maxval  = 0;
        }
        if(!$deltacalc) {
          $cnt[$i]++;
          $lastv[$i] = $sql_value;
        } else {
          $lastv[$i] = $out_value if($out_value);
        }
        $lastd[$i] = $sql_timestamp;
      }
    } #while fetchrow

    ######## den letzten Abschlusssatz rausschreiben ##########
    if($readings[$i]->[3] && ($readings[$i]->[3] eq "delta-h" || $readings[$i]->[3] eq "delta-d")) {
      if($lastd[$i] eq "undef") {
        $out_value  = "0";
        $out_tstamp = DbLog_implode_datetime($from_datetime{year}, $from_datetime{month}, $from_datetime{day}, $from_datetime{hour}, "30", "00") if($readings[$i]->[3] eq "delta-h");
        $out_tstamp = DbLog_implode_datetime($from_datetime{year}, $from_datetime{month}, $from_datetime{day}, "12", "00", "00") if($readings[$i]->[3] eq "delta-d");
      } else {
        %lasttstamp = DbLog_explode_datetime($lastd[$i], ());
        $out_value = sprintf("%g", $maxval - $minval);
        $out_tstamp = DbLog_implode_datetime($lasttstamp{year}, $lasttstamp{month}, $lasttstamp{day}, $lasttstamp{hour}, "30", "00") if($readings[$i]->[3] eq "delta-h");
        $out_tstamp = DbLog_implode_datetime($lasttstamp{year}, $lasttstamp{month}, $lasttstamp{day}, "12", "00", "00") if($readings[$i]->[3] eq "delta-d");
      }  
      $sum[$i] += $out_value;
      $cnt[$i]++;
      if($outf =~ m/(all)/) {
        $retval .= sprintf("%s: %s %s %s %s %s %s\n", $out_tstamp, $sql_device, $type, $event, $sql_reading, $out_value, $unit);
      
      } elsif ($outf =~ m/(array)/) {
        push(@ReturnArray, {"tstamp" => $out_tstamp, "device" => $sql_device, "type" => $type, "event" => $event, "reading" => $sql_reading, "value" => $out_value, "unit" => $unit});
          
      } else {
        $out_tstamp =~ s/\ /_/g; #needed by generating plots
        $retval .= "$out_tstamp $out_value\n";
      }
    }
    # DatenTrenner setzen
    $retval .= "#$readings[$i]->[0]";
    $retval .= ":";
    $retval .= "$readings[$i]->[1]" if($readings[$i]->[1]);
    $retval .= ":";
    $retval .= "$readings[$i]->[2]" if($readings[$i]->[2]);
    $retval .= ":";
    $retval .= "$readings[$i]->[3]" if($readings[$i]->[3]);
    $retval .= ":";
    $retval .= "$readings[$i]->[4]" if($readings[$i]->[4]);
    $retval .= "\n";
  } #for @readings

  #Ueberfuehren der gesammelten Werte in die globale Variable %data
  for(my $j=0; $j<int(@readings); $j++) {
    my $k = $j+1;
    $data{"min$k"} = $min[$j];
    $data{"max$k"} = $max[$j];
    $data{"avg$k"} = $cnt[$j] ? sprintf("%0.2f", $sum[$j]/$cnt[$j]) : 0;
    $data{"sum$k"} = $sum[$j];
    $data{"cnt$k"} = $cnt[$j];
    $data{"currval$k"} = $lastv[$j];
    $data{"currdate$k"} = $lastd[$j];
    $data{"mindate$k"} = $mind[$j];
    $data{"maxdate$k"} = $maxd[$j];
  }

  #cleanup (plotfork) connection
  # $dbh->disconnect() if( $hash->{PID} != $$ );
  $dbh->disconnect();

  if($internal) {
    $internal_data = \$retval;
    return undef;

  } elsif($outf =~ m/(array)/) {
    return @ReturnArray;
  
  } else {
    return $retval;
  }
}

#########################################################################################
### DBLog - Historische Werte ausduennen (alte blockiernde Variante) > Forum #41089
#########################################################################################
sub DbLog_reduceLog($@) {
    my ($hash,@a) = @_;
    my ($ret,$cmd,$row,$filter,$exclude,$c,$day,$hour,$lastHour,$updDate,$updHour,$average,$processingDay,$lastUpdH,%hourlyKnown,%averageHash,@excludeRegex,@dayRows,@averageUpd,@averageUpdD);
    my ($name,$startTime,$currentHour,$currentDay,$deletedCount,$updateCount,$sum,$rowCount,$excludeCount) = ($hash->{NAME},time(),99,0,0,0,0,0,0);
    my $dbh = DbLog_ConnectNewDBH($hash);
    return if(!$dbh);
  
    if ($a[-1] =~ /^EXCLUDE=(.+:.+)+/i) {
        ($filter) = $a[-1] =~ /^EXCLUDE=(.+)/i;
        @excludeRegex = split(',',$filter);
    } elsif ($a[-1] =~ /^INCLUDE=.+:.+$/i) {
        $filter = 1;
    }
    if (defined($a[3])) {
        $average = ($a[3] =~ /average=day/i) ? "AVERAGE=DAY" : ($a[3] =~ /average/i) ? "AVERAGE=HOUR" : 0;
    }
    Log3($name, 3, "DbLog $name: reduceLog requested with DAYS=$a[2]"
        .(($average || $filter) ? ', ' : '').(($average) ? "$average" : '')
        .(($average && $filter) ? ", " : '').(($filter) ? uc((split('=',$a[-1]))[0]).'='.(split('=',$a[-1]))[1] : ''));
    
    if ($hash->{DBMODEL} eq 'SQLITE')        { $cmd = "datetime('now', '-$a[2] days')"; }
    elsif ($hash->{DBMODEL} eq 'MYSQL')      { $cmd = "DATE_SUB(CURDATE(),INTERVAL $a[2] DAY)"; }
    elsif ($hash->{DBMODEL} eq 'POSTGRESQL') { $cmd = "NOW() - INTERVAL '$a[2]' DAY"; }
    else { $ret = 'Unknown database type.'; }
    
    if ($cmd) {
        my $sth_del = $dbh->prepare_cached("DELETE FROM history WHERE (DEVICE=?) AND (READING=?) AND (TIMESTAMP=?) AND (VALUE=?)");
        my $sth_upd = $dbh->prepare_cached("UPDATE history SET TIMESTAMP=?, EVENT=?, VALUE=? WHERE (DEVICE=?) AND (READING=?) AND (TIMESTAMP=?) AND (VALUE=?)");
        my $sth_delD = $dbh->prepare_cached("DELETE FROM history WHERE (DEVICE=?) AND (READING=?) AND (TIMESTAMP=?)");
        my $sth_updD = $dbh->prepare_cached("UPDATE history SET TIMESTAMP=?, EVENT=?, VALUE=? WHERE (DEVICE=?) AND (READING=?) AND (TIMESTAMP=?)");
        my $sth_get = $dbh->prepare("SELECT TIMESTAMP,DEVICE,'',READING,VALUE FROM history WHERE "
            .($a[-1] =~ /^INCLUDE=(.+):(.+)$/i ? "DEVICE like '$1' AND READING like '$2' AND " : '')
            ."TIMESTAMP < $cmd ORDER BY TIMESTAMP ASC");  # '' was EVENT, no longer in use
        $sth_get->execute();
        
        do {
            $row = $sth_get->fetchrow_arrayref || ['0000-00-00 00:00:00','D','','R','V'];  # || execute last-day dummy
            $ret = 1;
            ($day,$hour) = $row->[0] =~ /-(\d{2})\s(\d{2}):/;
            $rowCount++ if($day != 00);
            if ($day != $currentDay) {
                if ($currentDay) { # false on first executed day
                    if (scalar @dayRows) {
                        ($lastHour) = $dayRows[-1]->[0] =~ /(.*\d+\s\d{2}):/;
                        $c = 0;
                        for my $delRow (@dayRows) {
                            $c++ if($day != 00 || $delRow->[0] !~ /$lastHour/);
                        }
                        if($c) {
                            $deletedCount += $c;
                            Log3($name, 3, "DbLog $name: reduceLog deleting $c records of day: $processingDay");
                            $dbh->{RaiseError} = 1;
                            $dbh->{PrintError} = 0; 
                            $dbh->begin_work();
                            eval {
                                for my $delRow (@dayRows) {
                                    if($day != 00 || $delRow->[0] !~ /$lastHour/) {
                                        Log3($name, 5, "DbLog $name: DELETE FROM history WHERE (DEVICE=$delRow->[1]) AND (READING=$delRow->[3]) AND (TIMESTAMP=$delRow->[0]) AND (VALUE=$delRow->[4])");
                                        $sth_del->execute(($delRow->[1], $delRow->[3], $delRow->[0], $delRow->[4]));
                                    }
                                }
                            };
                            if ($@) {
                                Log3($hash->{NAME}, 3, "DbLog $name: reduceLog ! FAILED ! for day $processingDay");
                                $dbh->rollback();
                                $ret = 0;
                            } else {
                                $dbh->commit();
                            }
                            $dbh->{RaiseError} = 0; 
                            $dbh->{PrintError} = 1;
                        }
                        @dayRows = ();
                    }
                    
                    if ($ret && defined($a[3]) && $a[3] =~ /average/i) {
                        $dbh->{RaiseError} = 1;
                        $dbh->{PrintError} = 0; 
                        $dbh->begin_work();
                        eval {
                            push(@averageUpd, {%hourlyKnown}) if($day != 00);
                            
                            $c = 0;
                            for my $hourHash (@averageUpd) {  # Only count for logging...
                                for my $hourKey (keys %$hourHash) {
                                    $c++ if ($hourHash->{$hourKey}->[0] && scalar(@{$hourHash->{$hourKey}->[4]}) > 1);
                                }
                            }
                            $updateCount += $c;
                            Log3($name, 3, "DbLog $name: reduceLog (hourly-average) updating $c records of day: $processingDay") if($c); # else only push to @averageUpdD
                            
                            for my $hourHash (@averageUpd) {
                                for my $hourKey (keys %$hourHash) {
                                    if ($hourHash->{$hourKey}->[0]) { # true if reading is a number 
                                        ($updDate,$updHour) = $hourHash->{$hourKey}->[0] =~ /(.*\d+)\s(\d{2}):/;
                                        if (scalar(@{$hourHash->{$hourKey}->[4]}) > 1) {  # true if reading has multiple records this hour
                                            for (@{$hourHash->{$hourKey}->[4]}) { $sum += $_; }
                                            $average = sprintf('%.3f', $sum/scalar(@{$hourHash->{$hourKey}->[4]}) );
                                            $sum = 0;
                                            Log3($name, 5, "DbLog $name: UPDATE history SET TIMESTAMP=$updDate $updHour:30:00, EVENT='rl_av_h', VALUE=$average WHERE DEVICE=$hourHash->{$hourKey}->[1] AND READING=$hourHash->{$hourKey}->[3] AND TIMESTAMP=$hourHash->{$hourKey}->[0] AND VALUE=$hourHash->{$hourKey}->[4]->[0]");
                                            $sth_upd->execute(("$updDate $updHour:30:00", 'rl_av_h', $average, $hourHash->{$hourKey}->[1], $hourHash->{$hourKey}->[3], $hourHash->{$hourKey}->[0], $hourHash->{$hourKey}->[4]->[0]));
                                            push(@averageUpdD, ["$updDate $updHour:30:00", 'rl_av_h', $average, $hourHash->{$hourKey}->[1], $hourHash->{$hourKey}->[3], $updDate]) if (defined($a[3]) && $a[3] =~ /average=day/i);
                                        } else {
                                            push(@averageUpdD, [$hourHash->{$hourKey}->[0], $hourHash->{$hourKey}->[2], $hourHash->{$hourKey}->[4]->[0], $hourHash->{$hourKey}->[1], $hourHash->{$hourKey}->[3], $updDate]) if (defined($a[3]) && $a[3] =~ /average=day/i);
                                        }
                                    } 
                                }
                            }
                        };
                        if ($@) {
                            Log3($hash->{NAME}, 3, "DbLog $name: reduceLog average=hour ! FAILED ! for day $processingDay");
                            $dbh->rollback();
                            @averageUpdD = ();
                        } else {
                            $dbh->commit();
                        }
                        $dbh->{RaiseError} = 0; 
                        $dbh->{PrintError} = 1;
                        @averageUpd = ();
                    }
                    
                    if (defined($a[3]) && $a[3] =~ /average=day/i && scalar(@averageUpdD) && $day != 00) {
                        $dbh->{RaiseError} = 1;
                        $dbh->{PrintError} = 0;
                        $dbh->begin_work();
                        eval {
                            for (@averageUpdD) {
                                push(@{$averageHash{$_->[3].$_->[4]}->{tedr}}, [$_->[0], $_->[1], $_->[3], $_->[4]]);
                                $averageHash{$_->[3].$_->[4]}->{sum} += $_->[2];
                                $averageHash{$_->[3].$_->[4]}->{date} = $_->[5];
                            }
                            
                            $c = 0;
                            for (keys %averageHash) {
                                if(scalar @{$averageHash{$_}->{tedr}} == 1) {
                                    delete $averageHash{$_};
                                } else {
                                    $c += (scalar(@{$averageHash{$_}->{tedr}}) - 1);
                                }
                            }
                            $deletedCount += $c;
                            $updateCount += keys(%averageHash);
                            
                            Log3($name, 3, "DbLog $name: reduceLog (daily-average) updating ".(keys %averageHash).", deleting $c records of day: $processingDay") if(keys %averageHash);
                            for my $reading (keys %averageHash) {
                                $average = sprintf('%.3f', $averageHash{$reading}->{sum}/scalar(@{$averageHash{$reading}->{tedr}}));
                                $lastUpdH = pop @{$averageHash{$reading}->{tedr}};
                                for (@{$averageHash{$reading}->{tedr}}) {
                                    Log3($name, 5, "DbLog $name: DELETE FROM history WHERE DEVICE='$_->[2]' AND READING='$_->[3]' AND TIMESTAMP='$_->[0]'");
                                    $sth_delD->execute(($_->[2], $_->[3], $_->[0]));
                                }
                                Log3($name, 5, "DbLog $name: UPDATE history SET TIMESTAMP=$averageHash{$reading}->{date} 12:00:00, EVENT='rl_av_d', VALUE=$average WHERE (DEVICE=$lastUpdH->[2]) AND (READING=$lastUpdH->[3]) AND (TIMESTAMP=$lastUpdH->[0])");
                                $sth_updD->execute(($averageHash{$reading}->{date}." 12:00:00", 'rl_av_d', $average, $lastUpdH->[2], $lastUpdH->[3], $lastUpdH->[0]));
                            }
                        };
                        if ($@) {
                            Log3($hash->{NAME}, 3, "DbLog $name: reduceLog average=day ! FAILED ! for day $processingDay");
                            $dbh->rollback();
                        } else {
                            $dbh->commit();
                        }
                        $dbh->{RaiseError} = 0; 
                        $dbh->{PrintError} = 1;
                    }
                    %averageHash = ();
                    %hourlyKnown = ();
                    @averageUpd = ();
                    @averageUpdD = ();
                    $currentHour = 99;
                }
                $currentDay = $day;
            }
            
            if ($hour != $currentHour) { # forget records from last hour, but remember these for average
                if (defined($a[3]) && $a[3] =~ /average/i && keys(%hourlyKnown)) {
                    push(@averageUpd, {%hourlyKnown});
                }
                %hourlyKnown = ();
                $currentHour = $hour;
            }
            if (defined $hourlyKnown{$row->[1].$row->[3]}) { # remember first readings for device per h, other can be deleted
                push(@dayRows, [@$row]);
                if (defined($a[3]) && $a[3] =~ /average/i && defined($row->[4]) && $row->[4] =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/ && $hourlyKnown{$row->[1].$row->[3]}->[0]) {
                    if ($hourlyKnown{$row->[1].$row->[3]}->[0]) {
                        push(@{$hourlyKnown{$row->[1].$row->[3]}->[4]}, $row->[4]);
                    }
                }
            } else {
                $exclude = 0;
                for (@excludeRegex) {
                    $exclude = 1 if("$row->[1]:$row->[3]" =~ /^$_$/);
                }
                if ($exclude) {
                    $excludeCount++ if($day != 00);
                } else {
                    $hourlyKnown{$row->[1].$row->[3]} = (defined($row->[4]) && $row->[4] =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/) ? [$row->[0],$row->[1],$row->[2],$row->[3],[$row->[4]]] : [0];
                }
            }
            $processingDay = (split(' ',$row->[0]))[0];
        } while( $day != 00 );
        
        my $result = "Rows processed: $rowCount, deleted: $deletedCount"
                   .((defined($a[3]) && $a[3] =~ /average/i)? ", updated: $updateCount" : '')
                   .(($excludeCount)? ", excluded: $excludeCount" : '')
                   .", time: ".sprintf('%.2f',time() - $startTime)."sec";
        Log3($name, 3, "DbLog $name: reduceLog executed. $result");
		readingsSingleUpdate($hash,"reduceLogState",$result,1);
        $ret = "reduceLog executed. $result";
    }
    $dbh->disconnect(); 
    return $ret;
}

#########################################################################################
### DBLog - Historische Werte ausduennen non-blocking > Forum #41089
#########################################################################################
sub DbLog_reduceLogNbl($) {
    my ($name) = @_;
    my $hash   = $defs{$name};
    my $dbconn     = $hash->{dbconn};
    my $dbuser     = $hash->{dbuser};
    my $dbpassword = $attr{"sec$name"}{secret};
    my @a          = @{$hash->{HELPER}{REDUCELOG}};
    delete $hash->{HELPER}{REDUCELOG};
    my ($ret,$cmd,$row,$filter,$exclude,$c,$day,$hour,$lastHour,$updDate,$updHour,$average,$processingDay,$lastUpdH,%hourlyKnown,%averageHash,@excludeRegex,@dayRows,@averageUpd,@averageUpdD);
    my ($startTime,$currentHour,$currentDay,$deletedCount,$updateCount,$sum,$rowCount,$excludeCount) = (time(),99,0,0,0,0,0,0);
    my $dbh;
	
	Log3 ($name, 5, "DbLog $name -> Start DbLog_reduceLogNbl");
	
    eval {$dbh = DBI->connect("dbi:$dbconn", $dbuser, $dbpassword, { PrintError => 0, RaiseError => 1 }); };
	
    if ($@) {
        my $err = encode_base64($@,"");
        Log3 ($name, 2, "DbLog $name -> DbLog_reduceLogNbl - $@");
        Log3 ($name, 5, "DbLog $name -> DbLog_reduceLogNbl finished");
        return "$name|''|$err";
    }
  
    if ($a[-1] =~ /^EXCLUDE=(.+:.+)+/i) {
        ($filter) = $a[-1] =~ /^EXCLUDE=(.+)/i;
        @excludeRegex = split(',',$filter);
    } elsif ($a[-1] =~ /^INCLUDE=.+:.+$/i) {
        $filter = 1;
    }
    if (defined($a[3])) {
        $average = ($a[3] =~ /average=day/i) ? "AVERAGE=DAY" : ($a[3] =~ /average/i) ? "AVERAGE=HOUR" : 0;
    }
    Log3($name, 3, "DbLog $name: reduceLogNbl requested with DAYS=$a[2]"
        .(($average || $filter) ? ', ' : '').(($average) ? "$average" : '')
        .(($average && $filter) ? ", " : '').(($filter) ? uc((split('=',$a[-1]))[0]).'='.(split('=',$a[-1]))[1] : ''));
    
    if ($hash->{DBMODEL} eq 'SQLITE')        { $cmd = "datetime('now', '-$a[2] days')"; }
    elsif ($hash->{DBMODEL} eq 'MYSQL')      { $cmd = "DATE_SUB(CURDATE(),INTERVAL $a[2] DAY)"; }
    elsif ($hash->{DBMODEL} eq 'POSTGRESQL') { $cmd = "NOW() - INTERVAL '$a[2]' DAY"; }
    else { $ret = 'Unknown database type.'; }
    
    if ($cmd) {
	    my ($sth_del, $sth_upd, $sth_delD, $sth_updD, $sth_get);
        eval { $sth_del  = $dbh->prepare_cached("DELETE FROM history WHERE (DEVICE=?) AND (READING=?) AND (TIMESTAMP=?) AND (VALUE=?)");
               $sth_upd  = $dbh->prepare_cached("UPDATE history SET TIMESTAMP=?, EVENT=?, VALUE=? WHERE (DEVICE=?) AND (READING=?) AND (TIMESTAMP=?) AND (VALUE=?)");
               $sth_delD = $dbh->prepare_cached("DELETE FROM history WHERE (DEVICE=?) AND (READING=?) AND (TIMESTAMP=?)");
               $sth_updD = $dbh->prepare_cached("UPDATE history SET TIMESTAMP=?, EVENT=?, VALUE=? WHERE (DEVICE=?) AND (READING=?) AND (TIMESTAMP=?)");
               $sth_get  = $dbh->prepare("SELECT TIMESTAMP,DEVICE,'',READING,VALUE FROM history WHERE "
                           .($a[-1] =~ /^INCLUDE=(.+):(.+)$/i ? "DEVICE like '$1' AND READING like '$2' AND " : '')
                           ."TIMESTAMP < $cmd ORDER BY TIMESTAMP ASC");  # '' was EVENT, no longer in use
		     };
        if ($@) {
            my $err = encode_base64($@,"");
            Log3 ($name, 2, "DbLog $name -> DbLog_reduceLogNbl - $@");
            Log3 ($name, 5, "DbLog $name -> DbLog_reduceLogNbl finished");
            return "$name|''|$err";
        }
		
		eval { $sth_get->execute(); };
        if ($@) {
            my $err = encode_base64($@,"");
            Log3 ($name, 2, "DbLog $name -> DbLog_reduceLogNbl - $@");
            Log3 ($name, 5, "DbLog $name -> DbLog_reduceLogNbl finished");
            return "$name|''|$err";
        }
        
        do {
            $row = $sth_get->fetchrow_arrayref || ['0000-00-00 00:00:00','D','','R','V'];  # || execute last-day dummy
            $ret = 1;
            ($day,$hour) = $row->[0] =~ /-(\d{2})\s(\d{2}):/;
            $rowCount++ if($day != 00);
            if ($day != $currentDay) {
                if ($currentDay) { # false on first executed day
                    if (scalar @dayRows) {
                        ($lastHour) = $dayRows[-1]->[0] =~ /(.*\d+\s\d{2}):/;
                        $c = 0;
                        for my $delRow (@dayRows) {
                            $c++ if($day != 00 || $delRow->[0] !~ /$lastHour/);
                        }
                        if($c) {
                            $deletedCount += $c;
                            Log3($name, 3, "DbLog $name: reduceLogNbl deleting $c records of day: $processingDay");
                            $dbh->{RaiseError} = 1;
                            $dbh->{PrintError} = 0; 
                            eval { $dbh->begin_work(); };
						    if ($@) {
                                Log3 ($name, 2, "DbLog $name -> DbLog_reduceLogNbl - $@");
                            }
                            eval {
                                for my $delRow (@dayRows) {
                                    if($day != 00 || $delRow->[0] !~ /$lastHour/) {
                                        Log3($name, 5, "DbLog $name: DELETE FROM history WHERE (DEVICE=$delRow->[1]) AND (READING=$delRow->[3]) AND (TIMESTAMP=$delRow->[0]) AND (VALUE=$delRow->[4])");
                                        $sth_del->execute(($delRow->[1], $delRow->[3], $delRow->[0], $delRow->[4]));
                                    }
                                }
                            };
                            if ($@) {
                                Log3($hash->{NAME}, 3, "DbLog $name: reduceLogNbl ! FAILED ! for day $processingDay");
                                eval {$dbh->rollback() if(!$dbh->{AutoCommit});};
								if ($@) {
                                    Log3 ($name, 2, "DbLog $name -> DbLog_reduceLogNbl - $@");
                                }
                                $ret = 0;
                            } else {
                                eval {$dbh->commit() if(!$dbh->{AutoCommit});};
								if ($@) {
                                    Log3 ($name, 2, "DbLog $name -> DbLog_reduceLogNbl - $@");
                                }
                            }
                            $dbh->{RaiseError} = 0; 
                            $dbh->{PrintError} = 1;
                        }
                        @dayRows = ();
                    }
                    
                    if ($ret && defined($a[3]) && $a[3] =~ /average/i) {
                        $dbh->{RaiseError} = 1;
                        $dbh->{PrintError} = 0; 
                        eval { $dbh->begin_work(); };
						if ($@) {
                            Log3 ($name, 2, "DbLog $name -> DbLog_reduceLogNbl - $@");
                        }
                        eval {
                            push(@averageUpd, {%hourlyKnown}) if($day != 00);
                            
                            $c = 0;
                            for my $hourHash (@averageUpd) {  # Only count for logging...
                                for my $hourKey (keys %$hourHash) {
                                    $c++ if ($hourHash->{$hourKey}->[0] && scalar(@{$hourHash->{$hourKey}->[4]}) > 1);
                                }
                            }
                            $updateCount += $c;
                            Log3($name, 3, "DbLog $name: reduceLogNbl (hourly-average) updating $c records of day: $processingDay") if($c); # else only push to @averageUpdD
                            
                            for my $hourHash (@averageUpd) {
                                for my $hourKey (keys %$hourHash) {
                                    if ($hourHash->{$hourKey}->[0]) { # true if reading is a number 
                                        ($updDate,$updHour) = $hourHash->{$hourKey}->[0] =~ /(.*\d+)\s(\d{2}):/;
                                        if (scalar(@{$hourHash->{$hourKey}->[4]}) > 1) {  # true if reading has multiple records this hour
                                            for (@{$hourHash->{$hourKey}->[4]}) { $sum += $_; }
                                            $average = sprintf('%.3f', $sum/scalar(@{$hourHash->{$hourKey}->[4]}) );
                                            $sum = 0;
                                            Log3($name, 5, "DbLog $name: UPDATE history SET TIMESTAMP=$updDate $updHour:30:00, EVENT='rl_av_h', VALUE=$average WHERE DEVICE=$hourHash->{$hourKey}->[1] AND READING=$hourHash->{$hourKey}->[3] AND TIMESTAMP=$hourHash->{$hourKey}->[0] AND VALUE=$hourHash->{$hourKey}->[4]->[0]");
                                            $sth_upd->execute(("$updDate $updHour:30:00", 'rl_av_h', $average, $hourHash->{$hourKey}->[1], $hourHash->{$hourKey}->[3], $hourHash->{$hourKey}->[0], $hourHash->{$hourKey}->[4]->[0]));
                                            push(@averageUpdD, ["$updDate $updHour:30:00", 'rl_av_h', $average, $hourHash->{$hourKey}->[1], $hourHash->{$hourKey}->[3], $updDate]) if (defined($a[3]) && $a[3] =~ /average=day/i);
                                        } else {
                                            push(@averageUpdD, [$hourHash->{$hourKey}->[0], $hourHash->{$hourKey}->[2], $hourHash->{$hourKey}->[4]->[0], $hourHash->{$hourKey}->[1], $hourHash->{$hourKey}->[3], $updDate]) if (defined($a[3]) && $a[3] =~ /average=day/i);
                                        }
                                    } 
                                }
                            }
                        };
                        if ($@) {
                            Log3($hash->{NAME}, 3, "DbLog $name: reduceLogNbl average=hour ! FAILED ! for day $processingDay");
                            eval {$dbh->rollback() if(!$dbh->{AutoCommit});};
							if ($@) {
                                Log3 ($name, 2, "DbLog $name -> DbLog_reduceLogNbl - $@");
                            }
                            @averageUpdD = ();
                        } else {
                            eval {$dbh->commit() if(!$dbh->{AutoCommit});};
							if ($@) {
                                Log3 ($name, 2, "DbLog $name -> DbLog_reduceLogNbl - $@");
                            }							
                        }
                        $dbh->{RaiseError} = 0; 
                        $dbh->{PrintError} = 1;
                        @averageUpd = ();
                    }
                    
                    if (defined($a[3]) && $a[3] =~ /average=day/i && scalar(@averageUpdD) && $day != 00) {
                        $dbh->{RaiseError} = 1;
                        $dbh->{PrintError} = 0;
                        eval { $dbh->begin_work(); };
						if ($@) {
                            Log3 ($name, 2, "DbLog $name -> DbLog_reduceLogNbl - $@");
                        }
                        eval {
                            for (@averageUpdD) {
                                push(@{$averageHash{$_->[3].$_->[4]}->{tedr}}, [$_->[0], $_->[1], $_->[3], $_->[4]]);
                                $averageHash{$_->[3].$_->[4]}->{sum} += $_->[2];
                                $averageHash{$_->[3].$_->[4]}->{date} = $_->[5];
                            }
                            
                            $c = 0;
                            for (keys %averageHash) {
                                if(scalar @{$averageHash{$_}->{tedr}} == 1) {
                                    delete $averageHash{$_};
                                } else {
                                    $c += (scalar(@{$averageHash{$_}->{tedr}}) - 1);
                                }
                            }
                            $deletedCount += $c;
                            $updateCount += keys(%averageHash);
                            
                            Log3($name, 3, "DbLog $name: reduceLogNbl (daily-average) updating ".(keys %averageHash).", deleting $c records of day: $processingDay") if(keys %averageHash);
                            for my $reading (keys %averageHash) {
                                $average = sprintf('%.3f', $averageHash{$reading}->{sum}/scalar(@{$averageHash{$reading}->{tedr}}));
                                $lastUpdH = pop @{$averageHash{$reading}->{tedr}};
                                for (@{$averageHash{$reading}->{tedr}}) {
                                    Log3($name, 5, "DbLog $name: DELETE FROM history WHERE DEVICE='$_->[2]' AND READING='$_->[3]' AND TIMESTAMP='$_->[0]'");
                                    $sth_delD->execute(($_->[2], $_->[3], $_->[0]));
                                }
                                Log3($name, 5, "DbLog $name: UPDATE history SET TIMESTAMP=$averageHash{$reading}->{date} 12:00:00, EVENT='rl_av_d', VALUE=$average WHERE (DEVICE=$lastUpdH->[2]) AND (READING=$lastUpdH->[3]) AND (TIMESTAMP=$lastUpdH->[0])");
                                $sth_updD->execute(($averageHash{$reading}->{date}." 12:00:00", 'rl_av_d', $average, $lastUpdH->[2], $lastUpdH->[3], $lastUpdH->[0]));
                            }
                        };
                        if ($@) {
                            Log3($hash->{NAME}, 3, "DbLog $name: reduceLogNbl average=day ! FAILED ! for day $processingDay");
                            eval {$dbh->rollback() if(!$dbh->{AutoCommit});};
							if ($@) {
                                Log3 ($name, 2, "DbLog $name -> DbLog_reduceLogNbl - $@");
                            }
                        } else {
                            eval {$dbh->commit() if(!$dbh->{AutoCommit});};
							if ($@) {
                                Log3 ($name, 2, "DbLog $name -> DbLog_reduceLogNbl - $@");
                            }
                        }
                        $dbh->{RaiseError} = 0; 
                        $dbh->{PrintError} = 1;
                    }
                    %averageHash = ();
                    %hourlyKnown = ();
                    @averageUpd = ();
                    @averageUpdD = ();
                    $currentHour = 99;
                }
                $currentDay = $day;
            }
            
            if ($hour != $currentHour) { # forget records from last hour, but remember these for average
                if (defined($a[3]) && $a[3] =~ /average/i && keys(%hourlyKnown)) {
                    push(@averageUpd, {%hourlyKnown});
                }
                %hourlyKnown = ();
                $currentHour = $hour;
            }
            if (defined $hourlyKnown{$row->[1].$row->[3]}) { # remember first readings for device per h, other can be deleted
                push(@dayRows, [@$row]);
                if (defined($a[3]) && $a[3] =~ /average/i && defined($row->[4]) && $row->[4] =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/ && $hourlyKnown{$row->[1].$row->[3]}->[0]) {
                    if ($hourlyKnown{$row->[1].$row->[3]}->[0]) {
                        push(@{$hourlyKnown{$row->[1].$row->[3]}->[4]}, $row->[4]);
                    }
                }
            } else {
                $exclude = 0;
                for (@excludeRegex) {
                    $exclude = 1 if("$row->[1]:$row->[3]" =~ /^$_$/);
                }
                if ($exclude) {
                    $excludeCount++ if($day != 00);
                } else {
                    $hourlyKnown{$row->[1].$row->[3]} = (defined($row->[4]) && $row->[4] =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/) ? [$row->[0],$row->[1],$row->[2],$row->[3],[$row->[4]]] : [0];
                }
            }
            $processingDay = (split(' ',$row->[0]))[0];
        } while( $day != 00 );
        
        my $result = "Rows processed: $rowCount, deleted: $deletedCount"
                   .((defined($a[3]) && $a[3] =~ /average/i)? ", updated: $updateCount" : '')
                   .(($excludeCount)? ", excluded: $excludeCount" : '')
                   .", time: ".sprintf('%.2f',time() - $startTime)."sec";
        Log3($name, 3, "DbLog $name: reduceLogNbl finished. $result");
        $ret = $result;
        $ret = "reduceLogNbl finished. $result";
    }
    
	$dbh->disconnect();
    $ret = encode_base64($ret,"");
	Log3 ($name, 5, "DbLog $name -> DbLog_reduceLogNbl finished");
	
return "$name|$ret|0";
}

#########################################################################################
# DBLog - reduceLogNbl non-blocking Rückkehrfunktion
#########################################################################################
sub DbLog_reduceLogNbl_finished($) {
  my ($string)    = @_;
  my @a           = split("\\|",$string);
  my $name        = $a[0];
  my $hash        = $defs{$name};
  my $ret         = decode_base64($a[1]);
  my $err         = decode_base64($a[2]) if ($a[2]);
  
  readingsSingleUpdate($hash,"reduceLogState",$err?$err:$ret,1);
  delete $hash->{HELPER}{REDUCELOG_PID};
return;
}

#########################################################################################
# DBLog - count non-blocking
#########################################################################################
sub DbLog_countNbl($) {
  my ($name) = @_;
  my $hash   = $defs{$name};
  my ($cc,$hc,$bst,$st,$rt);
  
  # Background-Startzeit
  $bst = [gettimeofday];
  
  my $dbh = DbLog_ConnectNewDBH($hash);
  if (!$dbh) {
    my $err = encode_base64("DbLog $name: DBLog_Set - count - DB connect not possible","");
    return "$name|0|0|$err|0";
  } else {
    Log3 $name,4,"DbLog $name: Records count requested.";
	# SQL-Startzeit
    $st = [gettimeofday];
    $hc = $dbh->selectrow_array('SELECT count(*) FROM history');
    $cc = $dbh->selectrow_array('SELECT count(*) FROM current');
    $dbh->disconnect();
	# SQL-Laufzeit ermitteln
    $rt = tv_interval($st);
  }
  
  # Background-Laufzeit ermitteln
  my $brt = tv_interval($bst);
  $rt = $rt.",".$brt;
return "$name|$cc|$hc|0|$rt";
}

#########################################################################################
# DBLog - count non-blocking Rückkehrfunktion
#########################################################################################
sub DbLog_countNbl_finished($)
{
  my ($string) = @_;
  my @a        = split("\\|",$string);
  my $name     = $a[0];
  my $hash     = $defs{$name};
  my $cc       = $a[1];
  my $hc       = $a[2];
  my $err      = decode_base64($a[3]) if ($a[3]);
  my $bt       = $a[4] if($a[4]);  

  readingsSingleUpdate($hash,"state",$err,1) if($err);
  readingsSingleUpdate($hash,"countHistory",$hc,1) if ($hc);
  readingsSingleUpdate($hash,"countCurrent",$cc,1) if ($cc);
  
  if(AttrVal($name, "showproctime", undef) && $bt) {
      my ($rt,$brt)  = split(",", $bt);
      readingsBeginUpdate($hash);
      readingsBulkUpdate($hash, "background_processing_time", sprintf("%.4f",$brt));     
      readingsBulkUpdate($hash, "sql_processing_time", sprintf("%.4f",$rt));
      readingsEndUpdate($hash, 1);
  }
  delete $hash->{HELPER}{COUNT_PID};
return;
}

#########################################################################################
# DBLog - deleteOldDays non-blocking
#########################################################################################
sub DbLog_deldaysNbl($) {
  my ($name) = @_;
  my $hash   = $defs{$name};
  my $dbconn     = $hash->{dbconn};
  my $dbuser     = $hash->{dbuser};
  my $dbpassword = $attr{"sec$name"}{secret};
  my $days   = delete($hash->{HELPER}{DELDAYS});
  my ($cmd,$dbh,$rows,$error,$sth,$ret,$bst,$brt,$st,$rt);
  
  Log3 ($name, 5, "DbLog $name -> Start DbLog_deldaysNbl $days");
  
  # Background-Startzeit
  $bst = [gettimeofday];
  
  eval {$dbh = DBI->connect("dbi:$dbconn", $dbuser, $dbpassword, { PrintError => 0, RaiseError => 1 });};
  
  if ($@) {
      $error = encode_base64($@,"");
      Log3 ($name, 2, "DbLog $name - Error: $@");
      Log3 ($name, 5, "DbLog $name -> DbLog_deldaysNbl finished");
      return "$name|0|0|$error"; 
  }
  
  $cmd = "delete from history where TIMESTAMP < ";
  if ($hash->{DBMODEL} eq 'SQLITE') { 
      $cmd .= "datetime('now', '-$days days')"; 
  } elsif ($hash->{DBMODEL} eq 'MYSQL') { 
      $cmd .= "DATE_SUB(CURDATE(),INTERVAL $days DAY)"; 
  } elsif ($hash->{DBMODEL} eq 'POSTGRESQL') { 
      $cmd .= "NOW() - INTERVAL '$days' DAY"; 
  } else {  
	  $ret = 'Unknown database type. Maybe you can try userCommand anyway.';
	  $error = encode_base64($ret,"");
	  Log3 ($name, 2, "DbLog $name - Error: $ret");
      Log3 ($name, 5, "DbLog $name -> DbLog_deldaysNbl finished");
      return "$name|0|0|$error";  
  }
  
  # SQL-Startzeit
  $st = [gettimeofday];
    
  eval { 
      $sth = $dbh->prepare($cmd); 
      $sth->execute();
  };

  if ($@) {
      $error = encode_base64($@,"");
      Log3 ($name, 2, "DbLog $name - $@");
      $dbh->disconnect;
      Log3 ($name, 4, "DbLog $name -> BlockingCall DbLog_deldaysNbl finished");
      return "$name|0|0|$error"; 
 } else {
     $rows = $sth->rows;
     $dbh->commit() if(!$dbh->{AutoCommit});
     $dbh->disconnect;
 } 

 # SQL-Laufzeit ermitteln
 $rt = tv_interval($st);

 # Background-Laufzeit ermitteln
 $brt = tv_interval($bst);
 $rt = $rt.",".$brt;
  
  Log3 ($name, 5, "DbLog $name -> DbLog_deldaysNbl finished");
return "$name|$rows|$rt|0"; 
}

#########################################################################################
# DBLog - deleteOldDays non-blocking Rückkehrfunktion
#########################################################################################
sub DbLog_deldaysNbl_done($) {
  my ($string) = @_;
  my @a        = split("\\|",$string);
  my $name     = $a[0];
  my $hash     = $defs{$name};
  my $rows     = $a[1];
  my $bt       = $a[2] if($a[2]); 
  my $err      = decode_base64($a[3]) if ($a[3]);
 
  Log3 ($name, 5, "DbLog $name -> Start DbLog_deldaysNbl_done");
  
  if ($err) {
      readingsSingleUpdate($hash,"state",$err,1);
	  delete $hash->{HELPER}{DELDAYS_PID};
      Log3 ($name, 5, "DbLog $name -> DbLog_deldaysNbl_done finished");
      return;
  } else {
      if(AttrVal($name, "showproctime", undef) && $bt) {
          my ($rt,$brt)  = split(",", $bt);
          readingsBeginUpdate($hash);
          readingsBulkUpdate($hash, "background_processing_time", sprintf("%.4f",$brt));     
          readingsBulkUpdate($hash, "sql_processing_time", sprintf("%.4f",$rt));
          readingsEndUpdate($hash, 1);
	  }
	  readingsSingleUpdate($hash, "lastRowsDeleted", $rows ,1);
  }
  my $db = (split(/;|=/, $hash->{dbconn}))[1];
  Log3 ($name, 3, "DbLog $name -> deleteOldDays finished. $rows entries of database $db deleted.");
  delete $hash->{HELPER}{DELDAYS_PID};
  Log3 ($name, 5, "DbLog $name -> DbLog_deldaysNbl_done finished");
return;
}

################################################################
#
# Charting Specific functions start here
#
################################################################

################################################################
#
# Error handling, returns a JSON String
#
################################################################
sub jsonError($) {
  my $errormsg = $_[0]; 
  my $json = '{"success": "false", "msg":"'.$errormsg.'"}';
  return $json;
}


################################################################
#
# Prepare the SQL String
#
################################################################
sub prepareSql(@) {

    my ($hash, @a) = @_;
    my $starttime = $_[5];
    $starttime =~ s/_/ /;
    my $endtime   = $_[6];
    $endtime =~ s/_/ /;
    my $device = $_[7];
    my $userquery = $_[8];
    my $xaxis = $_[9]; 
    my $yaxis = $_[10]; 
    my $savename = $_[11]; 
    my $jsonChartConfig = $_[12];
    my $pagingstart = $_[13]; 
    my $paginglimit = $_[14]; 
    my $dbmodel = $hash->{DBMODEL};
    my ($sql, $jsonstring, $countsql, $hourstats, $daystats, $weekstats, $monthstats, $yearstats);

    if ($dbmodel eq "POSTGRESQL") {
        ### POSTGRESQL Queries for Statistics ###
        ### hour:
        $hourstats = "SELECT to_char(timestamp, 'YYYY-MM-DD HH24:00:00') AS TIMESTAMP, SUM(VALUE::float) AS SUM, ";
        $hourstats .= "AVG(VALUE::float) AS AVG, MIN(VALUE::float) AS MIN, MAX(VALUE::float) AS MAX, ";
        $hourstats .= "COUNT(VALUE) AS COUNT FROM history WHERE READING = '$yaxis' AND DEVICE = '$device' ";
        $hourstats .= "AND TIMESTAMP Between '$starttime' AND '$endtime' GROUP BY 1 ORDER BY 1;";

        ### day:
        $daystats = "SELECT to_char(timestamp, 'YYYY-MM-DD 00:00:00') AS TIMESTAMP, SUM(VALUE::float) AS SUM, ";
        $daystats .= "AVG(VALUE::float) AS AVG, MIN(VALUE::float) AS MIN, MAX(VALUE::float) AS MAX, ";
        $daystats .= "COUNT(VALUE) AS COUNT FROM history WHERE READING = '$yaxis' AND DEVICE = '$device' ";
        $daystats .= "AND TIMESTAMP Between '$starttime' AND '$endtime' GROUP BY 1 ORDER BY 1;";

        ### week:
        $weekstats = "SELECT date_trunc('week',timestamp) AS TIMESTAMP, SUM(VALUE::float) AS SUM, ";
        $weekstats .= "AVG(VALUE::float) AS AVG, MIN(VALUE::float) AS MIN, MAX(VALUE::float) AS MAX, ";
        $weekstats .= "COUNT(VALUE) AS COUNT FROM history WHERE READING = '$yaxis' AND DEVICE = '$device' ";
        $weekstats .= "AND TIMESTAMP Between '$starttime' AND '$endtime' GROUP BY 1 ORDER BY 1;";

        ### month:
        $monthstats = "SELECT to_char(timestamp, 'YYYY-MM-01 00:00:00') AS TIMESTAMP, SUM(VALUE::float) AS SUM, ";
        $monthstats .= "AVG(VALUE::float) AS AVG, MIN(VALUE::float) AS MIN, MAX(VALUE::float) AS MAX, ";
        $monthstats .= "COUNT(VALUE) AS COUNT FROM history WHERE READING = '$yaxis' AND DEVICE = '$device' ";
        $monthstats .= "AND TIMESTAMP Between '$starttime' AND '$endtime' GROUP BY 1 ORDER BY 1;";

        ### year:
        $yearstats = "SELECT to_char(timestamp, 'YYYY-01-01 00:00:00') AS TIMESTAMP, SUM(VALUE::float) AS SUM, ";
        $yearstats .= "AVG(VALUE::float) AS AVG, MIN(VALUE::float) AS MIN, MAX(VALUE::float) AS MAX, ";
        $yearstats .= "COUNT(VALUE) AS COUNT FROM history WHERE READING = '$yaxis' AND DEVICE = '$device' ";
        $yearstats .= "AND TIMESTAMP Between '$starttime' AND '$endtime' GROUP BY 1 ORDER BY 1;";
   
    } elsif ($dbmodel eq "MYSQL") {
        ### MYSQL Queries for Statistics ###
        ### hour:
        $hourstats = "SELECT date_format(timestamp, '%Y-%m-%d %H:00:00') AS TIMESTAMP, SUM(CAST(VALUE AS DECIMAL(12,4))) AS SUM, ";
        $hourstats .= "AVG(CAST(VALUE AS DECIMAL(12,4))) AS AVG, MIN(CAST(VALUE AS DECIMAL(12,4))) AS MIN, ";
        $hourstats .= "MAX(CAST(VALUE AS DECIMAL(12,4))) AS MAX, COUNT(VALUE) AS COUNT FROM history WHERE READING = '$yaxis' ";
        $hourstats .= "AND DEVICE = '$device' AND TIMESTAMP Between '$starttime' AND '$endtime' GROUP BY 1 ORDER BY 1;";

        ### day:
        $daystats = "SELECT date_format(timestamp, '%Y-%m-%d 00:00:00') AS TIMESTAMP, SUM(CAST(VALUE AS DECIMAL(12,4))) AS SUM, ";
        $daystats .= "AVG(CAST(VALUE AS DECIMAL(12,4))) AS AVG, MIN(CAST(VALUE AS DECIMAL(12,4))) AS MIN, ";
        $daystats .= "MAX(CAST(VALUE AS DECIMAL(12,4))) AS MAX, COUNT(VALUE) AS COUNT FROM history WHERE READING = '$yaxis' ";
        $daystats .= "AND DEVICE = '$device' AND TIMESTAMP Between '$starttime' AND '$endtime' GROUP BY 1 ORDER BY 1;";

        ### week:
        $weekstats = "SELECT date_format(timestamp, '%Y-%m-%d 00:00:00') AS TIMESTAMP, SUM(CAST(VALUE AS DECIMAL(12,4))) AS SUM, ";
        $weekstats .= "AVG(CAST(VALUE AS DECIMAL(12,4))) AS AVG, MIN(CAST(VALUE AS DECIMAL(12,4))) AS MIN, ";
        $weekstats .= "MAX(CAST(VALUE AS DECIMAL(12,4))) AS MAX, COUNT(VALUE) AS COUNT FROM history WHERE READING = '$yaxis' ";
        $weekstats .= "AND DEVICE = '$device' AND TIMESTAMP Between '$starttime' AND '$endtime' ";
        $weekstats .= "GROUP BY date_format(timestamp, '%Y-%u 00:00:00') ORDER BY 1;";

        ### month:
        $monthstats = "SELECT date_format(timestamp, '%Y-%m-01 00:00:00') AS TIMESTAMP, SUM(CAST(VALUE AS DECIMAL(12,4))) AS SUM, ";
        $monthstats .= "AVG(CAST(VALUE AS DECIMAL(12,4))) AS AVG, MIN(CAST(VALUE AS DECIMAL(12,4))) AS MIN, ";
        $monthstats .= "MAX(CAST(VALUE AS DECIMAL(12,4))) AS MAX, COUNT(VALUE) AS COUNT FROM history WHERE READING = '$yaxis' ";
        $monthstats .= "AND DEVICE = '$device' AND TIMESTAMP Between '$starttime' AND '$endtime' GROUP BY 1 ORDER BY 1;";

        ### year:
        $yearstats = "SELECT date_format(timestamp, '%Y-01-01 00:00:00') AS TIMESTAMP, SUM(CAST(VALUE AS DECIMAL(12,4))) AS SUM, ";
        $yearstats .= "AVG(CAST(VALUE AS DECIMAL(12,4))) AS AVG, MIN(CAST(VALUE AS DECIMAL(12,4))) AS MIN, ";
        $yearstats .= "MAX(CAST(VALUE AS DECIMAL(12,4))) AS MAX, COUNT(VALUE) AS COUNT FROM history WHERE READING = '$yaxis' ";
        $yearstats .= "AND DEVICE = '$device' AND TIMESTAMP Between '$starttime' AND '$endtime' GROUP BY 1 ORDER BY 1;";

    } elsif ($hash->{DBMODEL} eq "SQLITE") {
        ### SQLITE Queries for Statistics ###
        ### hour:
        $hourstats = "SELECT TIMESTAMP, SUM(CAST(VALUE AS FLOAT)) AS SUM, AVG(CAST(VALUE AS FLOAT)) AS AVG, ";
        $hourstats .= "MIN(CAST(VALUE AS FLOAT)) AS MIN, MAX(CAST(VALUE AS FLOAT)) AS MAX, COUNT(VALUE) AS COUNT ";
        $hourstats .= "FROM history WHERE READING = '$yaxis' AND DEVICE = '$device' ";
        $hourstats .= "AND TIMESTAMP Between '$starttime' AND '$endtime' GROUP BY strftime('%Y-%m-%d %H:00:00', TIMESTAMP);";
  
        ### day:
        $daystats = "SELECT TIMESTAMP, SUM(CAST(VALUE AS FLOAT)) AS SUM, AVG(CAST(VALUE AS FLOAT)) AS AVG, ";
        $daystats .= "MIN(CAST(VALUE AS FLOAT)) AS MIN, MAX(CAST(VALUE AS FLOAT)) AS MAX, COUNT(VALUE) AS COUNT ";
        $daystats .= "FROM history WHERE READING = '$yaxis' AND DEVICE = '$device' ";
        $daystats .= "AND TIMESTAMP Between '$starttime' AND '$endtime' GROUP BY strftime('%Y-%m-%d 00:00:00', TIMESTAMP);";

        ### week:
        $weekstats = "SELECT TIMESTAMP, SUM(CAST(VALUE AS FLOAT)) AS SUM, AVG(CAST(VALUE AS FLOAT)) AS AVG, ";
        $weekstats .= "MIN(CAST(VALUE AS FLOAT)) AS MIN, MAX(CAST(VALUE AS FLOAT)) AS MAX, COUNT(VALUE) AS COUNT ";
        $weekstats .= "FROM history WHERE READING = '$yaxis' AND DEVICE = '$device' ";
        $weekstats .= "AND TIMESTAMP Between '$starttime' AND '$endtime' GROUP BY strftime('%Y-%W 00:00:00', TIMESTAMP);";

        ### month:
        $monthstats = "SELECT TIMESTAMP, SUM(CAST(VALUE AS FLOAT)) AS SUM, AVG(CAST(VALUE AS FLOAT)) AS AVG, ";
        $monthstats .= "MIN(CAST(VALUE AS FLOAT)) AS MIN, MAX(CAST(VALUE AS FLOAT)) AS MAX, COUNT(VALUE) AS COUNT ";
        $monthstats .= "FROM history WHERE READING = '$yaxis' AND DEVICE = '$device' ";
        $monthstats .= "AND TIMESTAMP Between '$starttime' AND '$endtime' GROUP BY strftime('%Y-%m 00:00:00', TIMESTAMP);";

        ### year:
        $yearstats = "SELECT TIMESTAMP, SUM(CAST(VALUE AS FLOAT)) AS SUM, AVG(CAST(VALUE AS FLOAT)) AS AVG, ";
        $yearstats .= "MIN(CAST(VALUE AS FLOAT)) AS MIN, MAX(CAST(VALUE AS FLOAT)) AS MAX, COUNT(VALUE) AS COUNT ";
        $yearstats .= "FROM history WHERE READING = '$yaxis' AND DEVICE = '$device' ";
        $yearstats .= "AND TIMESTAMP Between '$starttime' AND '$endtime' GROUP BY strftime('%Y 00:00:00', TIMESTAMP);";

    } else {
        $sql = "errordb";
    }

    if($userquery eq "getreadings") {
        $sql = "SELECT distinct(reading) FROM history WHERE device = '".$device."'";
    } elsif($userquery eq "getdevices") {
        $sql = "SELECT distinct(device) FROM history";
    } elsif($userquery eq "timerange") {
        $sql = "SELECT ".$xaxis.", VALUE FROM history WHERE READING = '$yaxis' AND DEVICE = '$device' AND TIMESTAMP Between '$starttime' AND '$endtime' ORDER BY TIMESTAMP;";
    } elsif($userquery eq "hourstats") {
        $sql = $hourstats;
    } elsif($userquery eq "daystats") {
        $sql = $daystats;
    } elsif($userquery eq "weekstats") {
        $sql = $weekstats;
    } elsif($userquery eq "monthstats") {
        $sql = $monthstats;
    } elsif($userquery eq "yearstats") {
        $sql = $yearstats;
    } elsif($userquery eq "savechart") {
        $sql = "INSERT INTO frontend (TYPE, NAME, VALUE) VALUES ('savedchart', '$savename', '$jsonChartConfig')";
    } elsif($userquery eq "renamechart") {
        $sql = "UPDATE frontend SET NAME = '$savename' WHERE ID = '$jsonChartConfig'";
    } elsif($userquery eq "deletechart") {
        $sql = "DELETE FROM frontend WHERE TYPE = 'savedchart' AND ID = '".$savename."'";
    } elsif($userquery eq "updatechart") {
        $sql = "UPDATE frontend SET VALUE = '$jsonChartConfig' WHERE ID = '".$savename."'";
    } elsif($userquery eq "getcharts") {
        $sql = "SELECT * FROM frontend WHERE TYPE = 'savedchart'";
    } elsif($userquery eq "getTableData") {
        if ($device ne '""' && $yaxis ne '""') {
            $sql = "SELECT * FROM history WHERE READING = '$yaxis' AND DEVICE = '$device' ";
            $sql .= "AND TIMESTAMP Between '$starttime' AND '$endtime'";
            $sql .= " LIMIT '$paginglimit' OFFSET '$pagingstart'"; 
            $countsql = "SELECT count(*) FROM history WHERE READING = '$yaxis' AND DEVICE = '$device' "; 
            $countsql .= "AND TIMESTAMP Between '$starttime' AND '$endtime'"; 
        } elsif($device ne '""' && $yaxis eq '""') {  
            $sql = "SELECT * FROM history WHERE DEVICE = '$device' ";
            $sql .= "AND TIMESTAMP Between '$starttime' AND '$endtime'";
            $sql .= " LIMIT '$paginglimit' OFFSET '$pagingstart'";
            $countsql = "SELECT count(*) FROM history WHERE DEVICE = '$device' ";
            $countsql .= "AND TIMESTAMP Between '$starttime' AND '$endtime'";
        } else {
            $sql = "SELECT * FROM history";
            $sql .= " WHERE TIMESTAMP Between '$starttime' AND '$endtime'"; 
            $sql .= " LIMIT '$paginglimit' OFFSET '$pagingstart'";
            $countsql = "SELECT count(*) FROM history"; 
            $countsql .= " WHERE TIMESTAMP Between '$starttime' AND '$endtime'"; 
        }
        return ($sql, $countsql);
    } else {
        $sql = "error";
    }

    return $sql;
}

################################################################
#
# Do the query
#
################################################################
sub chartQuery($@) {

    my ($sql, $countsql) = prepareSql(@_);

    if ($sql eq "error") {
       return jsonError("Could not setup SQL String. Maybe the Database is busy, please try again!");
    } elsif ($sql eq "errordb") {
       return jsonError("The Database Type is not supported!");
    }

    my ($hash, @a) = @_;
	my $dbhf = DbLog_ConnectNewDBH($hash);
    return if(!$dbhf);

    my $totalcount;
    
    if (defined $countsql && $countsql ne "") {
        my $query_handle = $dbhf->prepare($countsql) 
        or return jsonError("Could not prepare statement: " . $dbhf->errstr . ", SQL was: " .$countsql);
        
        $query_handle->execute() 
        or return jsonError("Could not execute statement: " . $query_handle->errstr);

        my @data = $query_handle->fetchrow_array();
        $totalcount = join(", ", @data);
        
    }

    # prepare the query
    my $query_handle = $dbhf->prepare($sql) 
        or return jsonError("Could not prepare statement: " . $dbhf->errstr . ", SQL was: " .$sql);
    
    # execute the query
    $query_handle->execute() 
        or return jsonError("Could not execute statement: " . $query_handle->errstr);
    
    my $columns = $query_handle->{'NAME'};
    my $columncnt;

    # When columns are empty but execution was successful, we have done a successful INSERT, UPDATE or DELETE
    if($columns) {
        $columncnt = scalar @$columns;
    } else {
        return '{"success": "true", "msg":"All ok"}';
    }

    my $i = 0;
    my $jsonstring = '{"data":[';

    while ( my @data = $query_handle->fetchrow_array()) {

        if($i == 0) {
            $jsonstring .= '{';
        } else {
            $jsonstring .= ',{';
        } 
 
        for ($i = 0; $i < $columncnt; $i++) {
            $jsonstring .= '"';
            $jsonstring .= uc($query_handle->{NAME}->[$i]); 
            $jsonstring .= '":';

            if (defined $data[$i]) {
                my $fragment =  substr($data[$i],0,1);
                if ($fragment eq "{") {
                    $jsonstring .= $data[$i];
                } else {
                    $jsonstring .= '"'.$data[$i].'"';
                }
            } else {
                $jsonstring .= '""'
            }
            
            if($i != ($columncnt -1)) {
               $jsonstring .= ','; 
            }
        }
        $jsonstring .= '}'; 
    }
	$dbhf->disconnect();
    $jsonstring .= ']';
    if (defined $totalcount && $totalcount ne "") {
        $jsonstring .= ',"totalCount": '.$totalcount.'}';
    } else {
        $jsonstring .= '}';
    }
return $jsonstring;
}

#########################
sub
DbLog_fhemwebFn($$$$)
{
  my ($FW_wname, $d, $room, $pageHash) = @_; # pageHash is set for summaryFn.

   my $ret;
   my $newIdx=1;
   while($defs{"SVG_${d}_$newIdx"}) {
     $newIdx++;
   }
   my $name = "SVG_${d}_$newIdx";
   $ret .= FW_pH("cmd=define $name SVG $d:templateDB:HISTORY;".
                  "set $name copyGplotFile&detail=$name",
                  "<div class=\"dval\">Create SVG plot from DbLog</div>", 0, "dval", 1);
 
   return $ret;

}

sub
DbLog_sampleDataFn($$$$$)
{
  my ($dlName, $dlog, $max, $conf, $wName) = @_;
  my $desc = "Device:Reading";
  my @htmlArr;
  my @example;
  my @colregs;
  my $counter;
  # my $currentPresent = AttrVal($dlName,'DbLogType','Current');
  my $currentPresent = AttrVal($dlName,'DbLogType','History');  
  
  my $dbhf = DbLog_ConnectNewDBH($defs{$dlName});
  return if(!$dbhf);
  
  # check presence of table current
  # avoids fhem from crash if table 'current' is not present and attr DbLogType is set to /Current/
  my $prescurr = eval {$dbhf->selectrow_array("select count(*) from current");} || 0;
  Log3($dlName, 5, "DbLog $dlName: Table current present : $prescurr (0 = not present or no content)");
  
  if($currentPresent =~ m/Current/ && $prescurr) {
    # Table Current present, use it for sample data
    my $query = "select device,reading,value from current where device <> '' order by device,reading";
    my $sth = $dbhf->prepare( $query );  
    $sth->execute();
    while (my @line = $sth->fetchrow_array()) {
      $counter++;
      push (@example, join (" ",@line)) if($counter <= 8); # show max 8 examples
      push (@colregs, "$line[0]:$line[1]"); # push all eventTypes to selection list
    }
	$dbhf->disconnect(); 
    my $cols = join(",", sort @colregs);

    $max = 8 if($max > 8);
    for(my $r=0; $r < $max; $r++) {
      my @f = split(":", ($dlog->[$r] ? $dlog->[$r] : ":::"), 4);
      my $ret = "";
      $ret .= SVG_sel("par_${r}_0", $cols, "$f[0]:$f[1]");
#      $ret .= SVG_txt("par_${r}_2", "", $f[2], 1); # Default not yet implemented
#      $ret .= SVG_txt("par_${r}_3", "", $f[3], 3); # Function
#      $ret .= SVG_txt("par_${r}_4", "", $f[4], 3); # RegExp
      push @htmlArr, $ret;
    }

  } else {
  # Table Current not present, so create an empty input field
    push @example, "No sample data due to missing table 'Current'";

    $max = 8 if($max > 8);
    for(my $r=0; $r < $max; $r++) {
      my @f = split(":", ($dlog->[$r] ? $dlog->[$r] : ":::"), 4);
      my $ret = "";
      $ret .= SVG_txt("par_${r}_0", "", "$f[0]:$f[1]:$f[2]:$f[3]", 20);
#      $ret .= SVG_txt("par_${r}_2", "", $f[2], 1); # Default not yet implemented
#      $ret .= SVG_txt("par_${r}_3", "", $f[3], 3); # Function
#      $ret .= SVG_txt("par_${r}_4", "", $f[4], 3); # RegExp
      push @htmlArr, $ret;
    }

  }

  return ($desc, \@htmlArr, join("<br>", @example));
}

#
# get <dbLog> ReadingsVal       <device> <reading> <default>
# get <dbLog> ReadingsTimestamp <device> <reading> <default>
#
sub dbReadings($@) {
  my($hash,@a) = @_;
  
  my $dbhf = DbLog_ConnectNewDBH($hash);
  return if(!$dbhf);
  
  return 'Wrong Syntax for ReadingsVal!' unless defined($a[4]);
  my $DbLogType = AttrVal($a[0],'DbLogType','current');
  my $query;
  if (lc($DbLogType) =~ m(current) ) {
    $query = "select VALUE,TIMESTAMP from current where DEVICE= '$a[2]' and READING= '$a[3]'";
  } else {
    $query = "select VALUE,TIMESTAMP from history where DEVICE= '$a[2]' and READING= '$a[3]' order by TIMESTAMP desc limit 1";
  }
  my ($reading,$timestamp) = $dbhf->selectrow_array($query);
  $dbhf->disconnect(); 
  
  $reading = (defined($reading)) ? $reading : $a[4];
  $timestamp = (defined($timestamp)) ? $timestamp : $a[4];
  return $reading   if $a[1] eq 'ReadingsVal';
  return $timestamp if $a[1] eq 'ReadingsTimestamp';
  return "Syntax error: $a[1]";
}

################################################################
# benutzte DB-Feldlängen in Helper und Internals setzen
################################################################
sub setinternalcols ($){
  my ($hash)= @_;
  my $name = $hash->{NAME};

  $hash->{HELPER}{DEVICECOL}   = $columns{DEVICE};
  $hash->{HELPER}{TYPECOL}     = $columns{TYPE};
  $hash->{HELPER}{EVENTCOL}    = AttrVal($name, "colEvent", $columns{EVENT});
  $hash->{HELPER}{READINGCOL}  = AttrVal($name, "colReading", $columns{READING});
  $hash->{HELPER}{VALUECOL}    = AttrVal($name, "colValue", $columns{VALUE});
  $hash->{HELPER}{UNITCOL}     = $columns{UNIT};
  
  $hash->{COLUMNS} = "field length used for Device: $hash->{HELPER}{DEVICECOL}, Type: $hash->{HELPER}{TYPECOL}, Event: $hash->{HELPER}{EVENTCOL}, Reading: $hash->{HELPER}{READINGCOL}, Value: $hash->{HELPER}{VALUECOL}, Unit: $hash->{HELPER}{UNITCOL} ";

  # Statusbit "Columns sind gesetzt"
  $hash->{HELPER}{COLSET} = 1;

return;
}

################################################################
# reopen DB-Connection nach Ablauf set ... reopen [n] seconds
################################################################
sub reopen ($){
  my ($hash) = @_;
  my $name   = $hash->{NAME};
  my $async  = AttrVal($name, "asyncMode", undef);
  
  RemoveInternalTimer($hash, "reopen");
  
  if(DbLog_ConnectPush($hash)) {
      # Statusbit "Kein Schreiben in DB erlauben" löschen
      delete $hash->{HELPER}{REOPEN_RUNS};
	  Log3($name, 3, "DbLog $name: Database connection reopen request finished.");
	  readingsSingleUpdate($hash, "state", "reopened", 1);
	  DbLog_execmemcache($hash);
  } else {
      InternalTimer(gettimeofday()+30, "reopen", $hash, 0);		
  }
return;
}

################################################################
# check ob primary key genutzt wird
################################################################
sub checkUsePK ($$){
  my ($hash,$dbh) = @_;
  my $name   = $hash->{NAME};
  my $dbconn = $hash->{dbconn};
  my @usepkh = 0;
  my @usepkc = 0;
  
  my $db = (split("=",(split(";",$dbconn))[0]))[1];
  eval {@usepkh = $dbh->primary_key( undef, undef, 'history' );};
  eval {@usepkc = $dbh->primary_key( undef, undef, 'current' );};
  my $pkh = @usepkh?join(",",@usepkh):"none";
  my $pkc = @usepkc?join(",",@usepkc):"none";
  $pkh =~ tr/"//d;
  $pkc =~ tr/"//d;
  Log3 $hash->{NAME}, 5, "DbLog $name -> Primary Key used in $db.history: $pkh";
  Log3 $hash->{NAME}, 5, "DbLog $name -> Primary Key used in $db.current: $pkc";

  return (scalar(@usepkh),scalar(@usepkc),$pkh,$pkc);
}

1;

=pod
=item helper
=item summary    logs events into a database
=item summary_DE loggt Events in eine Datenbank
=begin html

<a name="DbLog"></a>
<h3>DbLog</h3>
<ul>
  <br>

  <a name="DbLogdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; DbLog &lt;configfilename&gt; &lt;regexp&gt;</code>
    <br><br>

    Log events to a database. The database connection is defined in
    <code>&lt;configfilename&gt;</code> (see sample configuration file
    <code>contrib/dblog/db.conf</code>). The configuration is stored in a separate file
    to avoid storing the password in the main configuration file and to have it
    visible in the output of the <a href="../docs/commandref.html#list">list</a> command.
    <br><br>
	
	DbLog distinguishes between the synchronous (default) and asynchronous logmode. The logmode is adjustable by the  
	<a href="#DbLogattr">attribute</a> asyncMode. Since version 2.13.5 DbLog is supporting primary key set in table 
	current	or history.
    <br><br>

    The modules <code>DBI</code> and <code>DBD::&lt;dbtype&gt;</code>
    need to be installed (use <code>cpan -i &lt;module&gt;</code>
    if your distribution does not have it).
    <br><br>

    <code>&lt;regexp&gt;</code> is the same as in <a href="../docs/commandref.html#FileLog">FileLog</a>.
    <br><br>
    Sample code to create a MySQL/PostgreSQL/SQLite database is in
    <code>&lt;DBType&gt;_create.sql</code>.
    The database contains two tables: <code>current</code> and
    <code>history</code>. The latter contains all events whereas the former only
    contains the last event for any given reading and device. (see also <a href="#DbLogattr">attribute</a> DbLogType)
	
    The columns have the following meaning: <br><br>
	
    <ol>
      <li>TIMESTAMP: timestamp of event, e.g. <code>2007-12-30 21:45:22</code></li>
      <li>DEVICE: device name, e.g. <code>Wetterstation</code></li>
      <li>TYPE: device type, e.g. <code>KS300</code></li>
      <li>EVENT: event specification as full string,
                                          e.g. <code>humidity: 71 (%)</code></li>
      <li>READING: name of reading extracted from event,
                      e.g. <code>humidity</code></li>

      <li>VALUE: actual reading extracted from event,
                      e.g. <code>71</code></li>
      <li>UNIT: unit extracted from event, e.g. <code>%</code></li>
    </ol>
	<br>
	
    The content of VALUE is optimized for automated post-processing, e.g.
    <code>yes</code> is translated to <code>1</code>
    <br><br>
    The current values can be retrieved by the following code like FileLog:<br>
    <ul>
      <code>get myDbLog - - 2012-11-10 2012-11-10 KS300:temperature::</code>
    </ul>
    <br><br>
    <b>Examples:</b>
    <ul>
        <code># log everything to database</code><br>

        <code>define myDbLog DbLog /etc/fhem/db.conf .*:.*</code>
    </ul>
  </ul>
  <br/><br/>

  <a name="DbLogset"></a>
  <b>Set</b> 
  <ul>
    <code>set &lt;name&gt; clearReadings </code><br><br>
      <ul> This function clears readings which were created by different DbLog-functions. </ul><br>
	  
    <code>set &lt;name&gt; eraseReadings </code><br><br>
      <ul> This function deletes all readings except reading "state". </ul><br>
	  
    <code>set &lt;name&gt; commitCache </code><br><br>
      <ul>In asynchronous mode (<a href="#DbLogattr">attribute</a> asyncMode=1), the cached data in memory will be written into the database 
	  and subsequently the cache will be cleared. Thereby the internal timer for the asynchronous mode Modus will be set new.
      The command can be usefull in case of you want to write the cached data manually or e.g. by an AT-device on a defined 
	  point of time into the database. </ul><br>
	  
    <code>set &lt;name&gt; reopen [n] </code><br/><br/>
      <ul>Perform a database disconnect and immediate reconnect to clear cache and flush journal file if no time [n] was set. <br>
	  If optionally a delay time of [n] seconds was set, the database connection will be disconnect immediately but it was only reopened 
	  after [n] seconds. In synchronous mode the events won't saved during that time. In asynchronous mode the events will be
	  stored in the memory cache and saved into database after the reconnect was done. </ul><br/>

    <code>set &lt;name&gt; rereadcfg </code><br/><br/>
      <ul>Perform a database disconnect and immediate reconnect to clear cache and flush journal file.<br/>
      Probably same behavior als reopen, but rereadcfg will read the configuration data before reconnect.</ul><br/>
	  
    <code>set &lt;name&gt; listCache </code><br><br>
      <ul>If DbLog is set to asynchronous mode (attribute asyncMode=1), you can use that command to list the events are cached in memory.</ul><br>

    <code>set &lt;name&gt; count </code><br/><br/>
      <ul>Count records in tables current and history and write results into readings countCurrent and countHistory.</ul><br/>

    <code>set &lt;name&gt; countNbl </code><br/><br/>
      <ul>The non-blocking execution of "set &lt;name&gt; count".</ul><br/>

    <code>set &lt;name&gt; deleteOldDays &lt;n&gt;</code><br/><br/>
      <ul>Delete records from history older than &lt;n&gt; days. Number of deleted records will be written into reading lastRowsDeleted.</ul><br/>
	  
    <code>set &lt;name&gt; deleteOldDaysNbl &lt;n&gt;</code><br/><br/>
      <ul>Is identical to function "deleteOldDays" 	whereupon deleteOldDaysNbl will be executed non-blocking. </ul><br/>	

    <code>set &lt;name&gt; purgeCache </code><br><br>
      <ul>In asynchronous mode (<a href="#DbLogattr">attribute</a> asyncMode=1), the in memory cached data will be deleted. 
      With this command data won't be written from cache into the database. </ul><br>
	  
    <code>set &lt;name&gt; reduceLog &lt;n&gt; [average[=day]] [exclude=deviceRegExp1:ReadingRegExp1,deviceRegExp2:ReadingRegExp2,...]</code> <br><br>
      <ul>Reduces records older than &lt;n&gt; days to one record each hour (the 1st) per device & reading. <br><br>
          <b>CAUTION:</b> It is strongly recommended to check if the default INDEX 'Search_Idx' exists on the table 'history'! <br>
		  The execution of this command may take (without INDEX) extremely long. FHEM will be <b>blocked completely</b> after issuing the command to completion ! <br><br>
          
		  With the optional argument 'average' not only the records will be reduced, but all numerical values of an hour 
		  will be reduced to a single average. <br>
          With the optional argument 'average=day' not only the records will be reduced, but all numerical values of a 
		  day will be reduced to a single average. (implies 'average') <br>
          You can optional set the last argument to "EXCLUDE=deviceRegExp1:ReadingRegExp1,deviceRegExp2:ReadingRegExp2,...." 
		  to exclude device/readings from reduceLog. <br>
          You can optional set the last argument to "INCLUDE=Database-deviceRegExp:Database-ReadingRegExp" to delimit 
		  the SELECT statement which is executet on the database. This reduces the system RAM load and increases the 
		  performance. (Wildcards are % and _) <br>
      </ul><br>
	  
    <code>set &lt;name&gt; reduceLogNbl &lt;n&gt; [average[=day]] [exclude=deviceRegExp1:ReadingRegExp1,deviceRegExp2:ReadingRegExp2,...]</code> <br><br>
      <ul>Same function as "set &lt;name&gt; reduceLog" but FHEM won't be blocked due to this function is implemented non-blocking ! <br>
      </ul><br>

    <code>set &lt;name&gt; userCommand &lt;validSqlStatement&gt;</code><br/><br/>
      <ul><b>DO NOT USE THIS COMMAND UNLESS YOU REALLY (REALLY!) KNOW WHAT YOU ARE DOING!!!</b><br/><br/>
          Perform any (!!!) sql statement on connected database. Useercommand and result will be written into corresponding readings.<br/>
      </ul><br/>

  </ul><br>

  <a name="DbLogget"></a>
  <b>Get</b>
  <ul>
  <code>get &lt;name&gt; ReadingsVal&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &lt;device&gt; &lt;reading&gt; &lt;default&gt;</code><br/>
  <code>get &lt;name&gt; ReadingsTimestamp &lt;device&gt; &lt;reading&gt; &lt;default&gt;</code><br/>
  <br/>
  Retrieve one single value, use and syntax are similar to ReadingsVal() and ReadingsTimestamp() functions.<br/>
  </ul>
  <br/>
  <br/>
  <ul>
    <code>get &lt;name&gt; &lt;infile&gt; &lt;outfile&gt; &lt;from&gt;
          &lt;to&gt; &lt;column_spec&gt; </code>
    <br><br>
    Read data from the Database, used by frontends to plot data without direct
    access to the Database.<br>

    <ul>
      <li>&lt;in&gt;<br>
        A dummy parameter for FileLog compatibility. Sessing by defaultto <code>-</code><br>
        <ul>
          <li>current: reading actual readings from table "current"</li>
          <li>history: reading history readings from table "history"</li>
          <li>-: identical to "history"</li>
        </ul> 
      </li>
      <li>&lt;out&gt;<br>
        A dummy parameter for FileLog compatibility. Setting by default to <code>-</code>
        to check the output for plot-computing.<br>
        Set it to the special keyword
        <code>all</code> to get all columns from Database.
        <ul>
          <li>ALL: get all colums from table, including a header</li>
          <li>Array: get the columns as array of hashes</li>
          <li>INT: internally used by generating plots</li>
          <li>-: default</li>
        </ul>
      </li>
      <li>&lt;from&gt; / &lt;to&gt;<br>
        Used to select the data. Please use the following timeformat or
        an initial substring of it:<br>
        <ul><code>YYYY-MM-DD_HH24:MI:SS</code></ul></li>
      <li>&lt;column_spec&gt;<br>
        For each column_spec return a set of data separated by
        a comment line on the current connection.<br>
        Syntax: &lt;device&gt;:&lt;reading&gt;:&lt;default&gt;:&lt;fn&gt;:&lt;regexp&gt;<br>
        <ul>
          <li>&lt;device&gt;<br>
            The name of the device. Case sensitive. Using a the joker "%" is supported.</li>
          <li>&lt;reading&gt;<br>
            The reading of the given device to select. Case sensitive. Using a the joker "%" is supported.
            </li>
          <li>&lt;default&gt;<br>
            no implemented yet
            </li>
          <li>&lt;fn&gt;
            One of the following:
            <ul>
              <li>int<br>
                Extract the integer at the beginning of the string. Used e.g.
                for constructs like 10%</li>
              <li>int&lt;digit&gt;<br>
                Extract the decimal digits including negative character and
                decimal point at the beginning og the string. Used e.g.
                for constructs like 15.7&deg;C</li>
              <li>delta-h / delta-d<br>
                Return the delta of the values for a given hour or a given day.
                Used if the column contains a counter, as is the case for the
                KS300 rain column.</li>
              <li>delta-ts<br>
                Replaced the original value with a measured value of seconds since
                the last and the actual logentry.
              </li>
            </ul></li>
            <li>&lt;regexp&gt;<br>
              The string is evaluated as a perl expression.  The regexp is executed
              before &lt;fn&gt; parameter.<br>
              Note: The string/perl expression cannot contain spaces,
              as the part after the space will be considered as the
              next column_spec.<br>
              <b>Keywords</b>
              <li>$val is the current value returned from the Database.</li>
              <li>$ts is the current timestamp returned from the Database.</li>
              <li>This Logentry will not print out if $val contains th keyword "hide".</li>
              <li>This Logentry will not print out and not used in the following processing
                  if $val contains th keyword "ignore".</li>
            </li>
        </ul></li>
      </ul>
    <br><br>
    Examples:
      <ul>
        <li><code>get myDbLog - - 2012-11-10 2012-11-20 KS300:temperature</code></li>
        <li><code>get myDbLog current ALL - - %:temperature</code></li><br>
            you will get all actual readings "temperature" from all logged devices. 
            Be carful by using "history" as inputfile because a long execution time will be expected!
        <li><code>get myDbLog - - 2012-11-10_10 2012-11-10_20 KS300:temperature::int1</code><br>
           like from 10am until 08pm at 10.11.2012</li>
        <li><code>get myDbLog - all 2012-11-10 2012-11-20 KS300:temperature</code></li>
        <li><code>get myDbLog - - 2012-11-10 2012-11-20 KS300:temperature KS300:rain::delta-h KS300:rain::delta-d</code></li>
        <li><code>get myDbLog - - 2012-11-10 2012-11-20 MyFS20:data:::$val=~s/(on|off).*/$1eq"on"?1:0/eg</code><br>
           return 1 for all occurance of on* (on|on-for-timer etc) and 0 for all off*</li>
        <li><code>get myDbLog - - 2012-11-10 2012-11-20 Bodenfeuchte:data:::$val=~s/.*B:\s([-\.\d]+).*/$1/eg</code><br>
           Example of OWAD: value like this: <code>"A: 49.527 % B: 66.647 % C: 9.797 % D: 0.097 V"</code><br>
           and output for port B is like this: <code>2012-11-20_10:23:54 66.647</code></li>
        <li><code>get DbLog - - 2013-05-26 2013-05-28 Pumpe:data::delta-ts:$val=~s/on/hide/</code><br>
           Setting up a "Counter of Uptime". The function delta-ts gets the seconds between the last and the
           actual logentry. The keyword "hide" will hide the logentry of "on" because this time 
           is a "counter of Downtime"</li>

      </ul>
    <br><br>
  </ul>

  <b>Get</b> when used for webcharts
  <ul>
    <code>get &lt;name&gt; &lt;infile&gt; &lt;outfile&gt; &lt;from&gt;
          &lt;to&gt; &lt;device&gt; &lt;querytype&gt; &lt;xaxis&gt; &lt;yaxis&gt; &lt;savename&gt; </code>
    <br><br>
    Query the Database to retrieve JSON-Formatted Data, which is used by the charting frontend.
    <br>

    <ul>
      <li>&lt;name&gt;<br>
        The name of the defined DbLog, like it is given in fhem.cfg.</li>
      <li>&lt;in&gt;<br>
        A dummy parameter for FileLog compatibility. Always set to <code>-</code></li>
      <li>&lt;out&gt;<br>
        A dummy parameter for FileLog compatibility. Set it to <code>webchart</code>
        to use the charting related get function.
      </li>
      <li>&lt;from&gt; / &lt;to&gt;<br>
        Used to select the data. Please use the following timeformat:<br>
        <ul><code>YYYY-MM-DD_HH24:MI:SS</code></ul></li>
      <li>&lt;device&gt;<br>
        A string which represents the device to query.</li>
      <li>&lt;querytype&gt;<br>
        A string which represents the method the query should use. Actually supported values are: <br>
          <code>getreadings</code> to retrieve the possible readings for a given device<br>
          <code>getdevices</code> to retrieve all available devices<br>
          <code>timerange</code> to retrieve charting data, which requires a given xaxis, yaxis, device, to and from<br>
          <code>savechart</code> to save a chart configuration in the database. Requires a given xaxis, yaxis, device, to and from, and a 'savename' used to save the chart<br>
          <code>deletechart</code> to delete a saved chart. Requires a given id which was set on save of the chart<br>
          <code>getcharts</code> to get a list of all saved charts.<br>
          <code>getTableData</code> to get jsonformatted data from the database. Uses paging Parameters like start and limit.<br>
          <code>hourstats</code> to get statistics for a given value (yaxis) for an hour.<br>
          <code>daystats</code> to get statistics for a given value (yaxis) for a day.<br>
          <code>weekstats</code> to get statistics for a given value (yaxis) for a week.<br>
          <code>monthstats</code> to get statistics for a given value (yaxis) for a month.<br>
          <code>yearstats</code> to get statistics for a given value (yaxis) for a year.<br>
      </li>
      <li>&lt;xaxis&gt;<br>
        A string which represents the xaxis</li>
      <li>&lt;yaxis&gt;<br>
         A string which represents the yaxis</li>
      <li>&lt;savename&gt;<br>
         A string which represents the name a chart will be saved with</li>
      <li>&lt;chartconfig&gt;<br>
         A jsonstring which represents the chart to save</li>
      <li>&lt;pagingstart&gt;<br>
         An integer used to determine the start for the sql used for query 'getTableData'</li>
      <li>&lt;paginglimit&gt;<br>
         An integer used to set the limit for the sql used for query 'getTableData'</li>
      </ul>
    <br><br>
    Examples:
      <ul>
        <li><code>get logdb - webchart "" "" "" getcharts</code><br>
            Retrieves all saved charts from the Database</li>
        <li><code>get logdb - webchart "" "" "" getdevices</code><br>
            Retrieves all available devices from the Database</li>
        <li><code>get logdb - webchart "" "" ESA2000_LED_011e getreadings</code><br>
            Retrieves all available Readings for a given device from the Database</li>
        <li><code>get logdb - webchart 2013-02-11_00:00:00 2013-02-12_00:00:00 ESA2000_LED_011e timerange TIMESTAMP day_kwh</code><br>
            Retrieves charting data, which requires a given xaxis, yaxis, device, to and from<br>
            Will ouput a JSON like this: <code>[{'TIMESTAMP':'2013-02-11 00:10:10','VALUE':'0.22431388090756'},{'TIMESTAMP'.....}]</code></li>
        <li><code>get logdb - webchart 2013-02-11_00:00:00 2013-02-12_00:00:00 ESA2000_LED_011e savechart TIMESTAMP day_kwh tageskwh</code><br>
            Will save a chart in the database with the given name and the chart configuration parameters</li>      
        <li><code>get logdb - webchart "" "" "" deletechart "" "" 7</code><br>
            Will delete a chart from the database with the given id</li>
      </ul>
    <br><br>
  </ul>
  
  <a name="DbLogattr"></a>
  <b>Attributes</b> 

  <ul><b>asyncMode</b>
    <ul>
	  <code>attr &lt;device&gt; asyncMode [1|0]
	  </code><br>
	  
      This attribute determines the operation mode of DbLog. If asynchronous mode is active (asyncMode=1), the events which should be saved 
	  at first will be cached in memory. After synchronisation time cycle (attribute syncInterval), or if the count limit of datasets in cache 
	  is reached (attribute cacheLimit), the cached events get saved into the database using bulk insert.
	  If the database isn't available, the events will be cached in memeory furthermore, and tried to save into database again after 
	  the next synchronisation time cycle if the database is available. <br>
	  In asynchronous mode the data insert into database will be executed non-blocking by a background process. 
	  You can adjust the timeout value for this background process by attribute "timeout" (default 120s). <br>
	  In synchronous mode (normal mode) the events won't be cached im memory and get saved into database immediately. If the database isn't
	  available the events are get lost. <br>
    </ul>
  </ul>
  <br>

  <ul><b>cacheEvents</b>
    <ul>
	  <code>attr &lt;device&gt; cacheEvents [2|1|0]
	  </code><br>
	  <ul>
      <li>cacheEvents=1: creates events of reading CacheUsage at point of time when a new dataset has been added to the cache. </li>
	  <li>cacheEvents=2: creates events of reading CacheUsage at point of time when in aychronous mode a new write cycle to the 
	                     database starts. In that moment CacheUsage contains the amount of datasets which will be written to 
						 the database. </li><br>
	  </ul>
    </ul>
  </ul>
  <br>
  
  <ul><b>cacheLimit</b>
     <ul>
	   <code>
	   attr &lt;device&gt; cacheLimit &lt;n&gt; 
	   </code><br>
	 
       In asynchronous logging mode the content of cache will be written into the database and cleared if the number &lt;n&gt; datasets
	   in cache has reached (default: 500). Thereby the timer of asynchronous logging mode will be set new to the value of 
	   attribute "syncInterval". <br>
     </ul>
  </ul>
  <br>
  
  <ul><b>colEvent</b>
     <ul>
	   <code>
	   attr &lt;device&gt; colEvent &lt;n&gt; 
	   </code><br>
	 
	   The field length of database field EVENT will be adjusted. By this attribute the default value in the DbLog-device can be
	   adjusted if the field length in the databse was changed nanually. If colEvent=0 is set, the database field  
	   EVENT won't be filled . <br>
	   <b>Note:</b> <br>
	   If the attribute is set, all of the field length limits are valid also for SQLite databases as noticed in Internal COLUMNS !  <br>
     </ul>
  </ul>
  <br>
  
  <ul><b>colReading</b>
     <ul>
	   <code>
	   attr &lt;device&gt; colReading &lt;n&gt; 
	   </code><br>
	 
	   The field length of database field READING will be adjusted. By this attribute the default value in the DbLog-device can be
	   adjusted if the field length in the databse was changed nanually. If colReading=0 is set, the database field  
	   READING won't be filled . <br>
	   <b>Note:</b> <br>
	   If the attribute is set, all of the field length limits are valid also for SQLite databases as noticed in Internal COLUMNS !  <br>
     </ul>
  </ul>
  <br>
  
  <ul><b>colValue</b>
     <ul>
	   <code>
	   attr &lt;device&gt; colValue &lt;n&gt; 
	   </code><br>
	 
	   The field length of database field VALUE will be adjusted. By this attribute the default value in the DbLog-device can be
	   adjusted if the field length in the databse was changed nanually. If colEvent=0 is set, the database field  
	   VALUE won't be filled . <br>
	   <b>Note:</b> <br>
	   If the attribute is set, all of the field length limits are valid also for SQLite databases as noticed in Internal COLUMNS !  <br>
     </ul>
  </ul>
  <br>
  
  <ul><b>DbLogType</b>
     <ul>
	   <code>
	   attr &lt;device&gt; DbLogType [Current|History|Current/History]
	   </code><br>
	 
       This attribute determines which table or which tables in the database are wanted to use. If the attribute isn't set, 
	   the table <i>history</i> will be used as default. <br>
	   <b>Note:</b> <br>
	   The current-table has to be used to get a Device:Reading-DropDown list when a SVG-Plot will be created. <br>
     </ul>
  </ul>
  <br>
  
  <ul><b>DbLogSelectionMode</b>
    <ul>
	  <code>
	  attr &lt;device&gt; DbLogSelectionMode [Exclude|Include|Exclude/Include]
	  </code><br>
	  
      Thise DbLog-Device-Attribute specifies how the device specific Attributes DbLogExclude and DbLogInclude are handled.
      If this Attribute is missing it defaults to "Exclude".
         <ul>
            <li>Exclude: DbLog behaves just as usual. This means everything specified in the regex in DEF will be logged by default and anything excluded
                         via the DbLogExclude attribute will not be logged</li>
            <li>Include: Nothing will be logged, except the readings specified via regex in the DbLogInclude attribute </li>
            <li>Exclude/Include: Just almost the same as Exclude, but if the reading matches the DbLogExclude attribute, then
                       it will further be checked against the regex in DbLogInclude whicht may possibly re-include the already 
                       excluded reading. </li>
         </ul>
    </ul>
  </ul>
  <br>

  <ul><b>DbLogInclude</b>
    <ul>
      <code>
      attr &lt;device&gt; DbLogInclude regex:MinInterval,[regex:MinInterval] ...
      </code><br>
	  
      A new Attribute DbLogInclude will be propagated
      to all Devices if DBLog is used. DbLogInclude works just like DbLogExclude but 
      to include matching readings.
      See also DbLogSelectionMode-Attribute of DbLog-Device which takes influence on 
      on how DbLogExclude and DbLogInclude are handled. <br>
	
	  <b>Example</b> <br>
      <code>attr MyDevice1 DbLogInclude .*</code> <br>
      <code>attr MyDevice2 DbLogInclude state,(floorplantext|MyUserReading):300,battery:3600</code>
    </ul>
  </ul>
  <br>
  
  <ul><b>DbLogExclude</b>
    <ul>
      <code>
      attr &lt;device&gt; DbLogExclude regex:MinInterval,[regex:MinInterval] ...
      </code><br>
	  
      A new Attribute DbLogExclude will be propagated to all Devices if DBLog is used. 
	  DbLogExclude will work as regexp to exclude defined readings to log. Each individual regexp-group are separated by comma. 
      If a MinInterval is set, the logentry is dropped if the defined interval is not reached and value vs. lastvalue is eqal. <br>
    
	  <b>Example</b> <br>
      <code>attr MyDevice1 DbLogExclude .*</code> <br>
      <code>attr MyDevice2 DbLogExclude state,(floorplantext|MyUserReading):300,battery:3600</code>
    </ul>
  </ul>
  <br>

  <ul><b>excludeDevs</b>
     <ul>
	   <code>
	   attr &lt;device&gt; excludeDevs &lt;device1&gt;,&lt;device2&gt;,&lt;device..&gt; 
	   </code><br>
      
	   The devices "device1", "device2" up to "device.." will be excluded from logging into database. This attribute will only be evaluated
	   if in DbLog-define ".*:.*" (that means all devices should be logged) is set. Thereby devices can be excluded explicitly instead of
	   include all relevant devices (devices want to log into database) in the DbLog-define (e.g. by string (device1|device2|device..):.* and so on).  
	   The devices to exclude are evaluated as Regex. <br>
	   
	   <b>Example</b> <br>
       <code>
	   attr &lt;device&gt; excludeDevs global,Log.*,Cam.*
	   </code><br>
	   # The devices global respectively devices starting with "Log" or "Cam" are excluded from database logging. <br>
     </ul>
  </ul>
  <br>
  
  <ul><b>noNotifyDev</b>
     <ul>
	   <code>
	   attr &lt;device&gt; noNotifyDev [1|0]
	   </code><br>
	   
       Enforces that NOTIFYDEV won't set and hence won't used. <br>
     </ul>
  </ul>
  <br>
  
  <ul><b>syncEvents</b>
    <ul>
	  <code>attr &lt;device&gt; syncEvents [1|0]
	  </code><br>
	  
      events of reading syncEvents will be created. <br>
    </ul>
  </ul>
  <br>

  <ul><b>shutdownWait</b>
    <ul>
	  <code>attr &lt;device&gt; shutdownWait <n>
	  </code><br>
      causes fhem shutdown to wait n seconds for pending database commit<br/>
    </ul>
  </ul>
  <br>
  
  <ul><b>showproctime</b>
    <ul>
	  <code>attr &lt;device&gt; [1|0]
	  </code><br>
	  
      If set, the reading "sql_processing_time" shows the required execution time (in seconds) for the sql-requests. This is not calculated 
	  for a single sql-statement, but the summary of all sql-statements necessary for within an executed DbLog-function in background. 
	  The reading "background_processing_time" shows the total time used in background.  <br>
    </ul>
  </ul>
  <br>

  <ul><b>showNotifyTime</b>
    <ul>
	  <code>attr &lt;device&gt; showNotifyTime [1|0]
	  </code><br>
	  
	  If set, the reading "notify_processing_time" shows the required execution time (in seconds) in the DbLog 
	  Notify-function. This attribute is practical for performance analyses and helps to determine the differences of time
      required when the operation mode was switched from synchronous to the asynchronous mode. <br>
	  
    </ul>
  </ul>
  <br>
  
  <ul><b>syncInterval</b>
    <ul>
	  <code>attr &lt;device&gt; syncInterval &lt;n&gt;
	  </code><br>
	  
      If DbLog is set to asynchronous operation mode (attribute asyncMode=1), with this attribute you can setup the interval in seconds
      used for storage the in memory cached events into the database. THe default value is 30 seconds. <br>
	  
    </ul>
  </ul>
  <br>
  
  <ul><b>suppressUndef</b>
    <ul>
	  <code>
	  attr &lt;device&gt; ignoreUndef <n>
	  </code><br>
      suppresses all undef values when returning data from the DB via get <br>

	  <b>Example</b> <br>
      <code>#DbLog eMeter:power:::$val=($val>1500)?undef:$val</code>
    </ul>
  </ul>
  <br>

  <ul><b>timeout</b>
    <ul>
	  <code>
	  attr &lt;device&gt; timeout <n>
	  </code><br>
      setup timeout of the write cycle into database in asynchronous mode (default 1800s) <br>

    </ul>
  </ul>
  <br>
  
  <ul><b>verbose4Devs</b>
     <ul>
	   <code>
	   attr &lt;device&gt; verbose4Devs &lt;device1&gt;,&lt;device2&gt;,&lt;device..&gt; 
	   </code><br>
      
	   If verbose level 4 is used, only output of devices set in this attribute will be reported in FHEM central logfile. If this attribute
	   isn't set, output of all relevant devices will be reported if using verbose level 4.
	   The given devices are evaluated as Regex. <br>
	   
	  <b>Example</b> <br>
      <code>
	  attr &lt;device&gt; verbose4Devs sys.*,.*5000.*,Cam.*,global
	  </code><br>
	  # The devices starting with "sys", "Cam" respectively devices are containing "5000" in its name and the device "global" will be reported in FHEM
	  central Logfile if verbose=4 is set. <br>
     </ul>
  </ul>
  <br>

</ul>

=end html
=begin html_DE

<a name="DbLog"></a>
<h3>DbLog</h3>
<ul>
  <br>

  <a name="DbLogdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; DbLog &lt;configfilename&gt; &lt;regexp&gt;</code>
    <br><br>

    Speichert Events in eine Datenbank. Die Datenbankverbindungsparameter werden
    definiert in <code>&lt;configfilename&gt;</code>. (Vergleiche
    Beipspielkonfigurationsdatei in <code>contrib/dblog/db.conf</code>).<br>
    Die Konfiguration ist in einer sparaten Datei abgelegt um das Datenbankpasswort
    nicht in Klartext in der FHEM-Haupt-Konfigurationsdatei speichern zu müssen.
    Ansonsten wäre es mittels des <a href="../docs/commandref.html#list">list</a>
    Befehls einfach auslesbar.
    <br><br>
	
	DbLog unterscheidet den synchronen (Default) und asynchronen Logmodus. Der Logmodus ist über das 
	<a href="#DbLogattr">Attribut</a> asyncMode einstellbar. Ab Version 2.13.5 unterstützt DbLog einen gesetzten
	Primary Key (PK) in den Tabellen Current und History.
    <br><br>

    Die Perl-Module <code>DBI</code> und <code>DBD::&lt;dbtype&gt;</code>
    müssen installiert werden (use <code>cpan -i &lt;module&gt;</code>
    falls die eigene Distribution diese nicht schon mitbringt). 
    <br><br>

    <code>&lt;regexp&gt;</code> ist identisch wie <a href="../docs/commandref.html#FileLog">FileLog</a>.
    <br><br>
    Ein Beispielcode zum Erstellen einer MySQL/PostgreSQL/SQLite Datenbank ist in
    <code>contrib/dblog/&lt;DBType&gt;_create.sql</code> zu finden.
    Die Datenbank beinhaltet 2 Tabellen: <code>current</code> und
    <code>history</code>. Die Tabelle <code>current</code> enthält den letzten Stand
    pro Device und Reading. In der Tabelle <code>history</code> sind alle
    Events historisch gespeichert. (siehe auch <a href="#DbLogattr">Attribut</a> DbLogType)

    Die Tabellenspalten haben folgende Bedeutung: <br><br>
	
    <ol>
      <li>TIMESTAMP: Zeitpunkt des Events, z.B. <code>2007-12-30 21:45:22</code></li>
      <li>DEVICE: name des Devices, z.B. <code>Wetterstation</code></li>
      <li>TYPE: Type des Devices, z.B. <code>KS300</code></li>
      <li>EVENT: das auftretende Event als volle Zeichenkette
                                          z.B. <code>humidity: 71 (%)</code></li>
      <li>READING: Name des Readings, ermittelt aus dem Event,
                      z.B. <code>humidity</code></li>

      <li>VALUE: aktueller Wert des Readings, ermittelt aus dem Event,
                      z.B. <code>71</code></li>
      <li>UNIT: Einheit, ermittelt aus dem Event, z.B. <code>%</code></li>
    </ol>
	<br>
	
    Der Wert des Readings ist optimiert für eine automatisierte Nachverarbeitung
    z.B. <code>yes</code> ist transformiert nach <code>1</code>
    <br><br>
    Die gespeicherten Werte können mittels GET Funktion angezeigt werden:
    <ul>
      <code>get myDbLog - - 2012-11-10 2012-11-10 KS300:temperature</code>
    </ul>
    <br><br>
    <b>Beispiel:</b>
    <ul>
        <code>Speichert alles in der Datenbank</code><br>
        <code>define myDbLog DbLog /etc/fhem/db.conf .*:.*</code>
    </ul>
  </ul>


  <a name="DbLogset"></a>
  <b>Set</b> 
  <ul>
    <code>set &lt;name&gt; clearReadings </code><br><br>
      <ul> Leert Readings die von verschiedenen DbLog-Funktionen angelegt wurden. </ul><br>
	  
    <code>set &lt;name&gt; eraseReadings </code><br><br>
      <ul> Löscht alle Readings auper dem Reading "state". </ul><br>
	  
    <code>set &lt;name&gt; commitCache </code><br><br>
      <ul>Im asynchronen Modus (<a href="#DbLogattr">Attribut</a> asyncMode=1), werden die im Speicher gecachten Daten in die Datenbank geschrieben 
	  und danach der Cache geleert. Der interne Timer des asynchronen Modus wird dabei neu gesetzt.
      Der Befehl kann nützlich sein um manuell oder z.B. über ein AT den Cacheinhalt zu einem definierten Zeitpunkt in die 
	  Datenbank zu schreiben. </ul><br>
	  
    <code>set &lt;name&gt; reopen [n]</code><br/><br/>
      <ul>Schließt die Datenbank und öffnet sie danach sofort wieder wenn keine Zeit [n] in Sekunden angegeben wurde. 
	  Dabei wird die Journaldatei geleert und neu angelegt.<br/>
      Verbessert den Datendurchsatz und vermeidet Speicherplatzprobleme. <br>
	  Wurde eine optionale Verzögerungszeit [n] in Sekunden angegeben, wird die Verbindung zur Datenbank geschlossen und erst 
	  nach Ablauf von [n] Sekunden wieder neu verbunden. 
	  Im synchronen Modus werden die Events in dieser Zeit nicht gespeichert. 
	  Im asynchronen Modus werden die Events im Cache gespeichert und nach dem Reconnect in die Datenbank geschrieben. </ul><br>

    <code>set &lt;name&gt; rereadcfg </code><br/><br/>
      <ul>Schließt die Datenbank und öffnet sie danach sofort wieder. Dabei wird die Journaldatei geleert und neu angelegt.<br/>
      Verbessert den Datendurchsatz und vermeidet Speicherplatzprobleme.<br/>
      Zwischen dem Schließen der Verbindung und dem Neuverbinden werden die Konfigurationsdaten neu gelesen</ul><br/>
	  
    <code>set &lt;name&gt; listCache </code><br><br>
      <ul>Wenn DbLog im asynchronen Modus betrieben wird (Attribut asyncMode=1), können mit diesem Befehl die im Speicher gecachten Events 
	  angezeigt werden.</ul><br>

    <code>set &lt;name&gt; count </code><br/><br/>
      <ul>Zählt die Datensätze in den Tabellen current und history und schreibt die Ergebnisse in die Readings 
	  countCurrent und countHistory.</ul><br/>
	  
    <code>set &lt;name&gt; countNbl </code><br/><br/>
      <ul>Die non-blocking Ausführung von "set &lt;name&gt; count".</ul><br/>

    <code>set &lt;name&gt; deleteOldDays &lt;n&gt;</code><br/><br/>
      <ul>Löscht Datensätze in Tabelle history, die älter sind als &lt;n&gt; Tage sind. 
	  Die Anzahl der gelöschten Datens&auml;tze wird in das Reading lastRowsDeleted geschrieben.</ul><br/>

    <code>set &lt;name&gt; deleteOldDaysNbl &lt;n&gt;</code><br/><br/>
      <ul>Identisch zu Funktion "deleteOldDays" wobei deleteOldDaysNbl nicht blockierend ausgeführt wird. </ul><br/>	  
	  
    <code>set &lt;name&gt; purgeCache </code><br><br>
      <ul>Im asynchronen Modus (<a href="#DbLogattr">Attribut</a> asyncMode=1), werden die im Speicher gecachten Daten gelöscht. 
      Es werden keine Daten aus dem Cache in die Datenbank geschrieben. </ul><br>
	  
    <code>set &lt;name&gt; reduceLog &lt;n&gt; [average[=day]] [exclude=deviceRegExp1:ReadingRegExp1,deviceRegExp2:ReadingRegExp2,...]</code><br><br>
      <ul>Reduziert historische Datensaetze, die älter sind als &lt;n&gt; Tage auf einen Eintrag pro Stunde (den ersten) je Device & Reading.<br><br>
          <b>ACHTUNG:</b> Es wird dringend empfohlen zu überprüfen ob der standard INDEX 'Search_Idx' in der Tabelle 'history' existiert! <br>
		  Die Abarbeitung dieses Befehls dauert unter Umständen (ohne INDEX) extrem lange. FHEM wird durch den Befehl bis 
		  zur Fertigstellung <b>komplett blockiert !</b> <br><br>
		  
		  Das Reading "reduceLogState" zeigt den Ausführungsstatus des letzten reduceLog-Befehls. <br><br>
          Durch die optionale Angabe von 'average' wird nicht nur die Datenbank bereinigt, sondern alle numerischen Werte 
		  einer Stunde werden auf einen einzigen Mittelwert reduziert. <br>
          Durch die optionale Angabe von 'average=day' wird nicht nur die Datenbank bereinigt, sondern alle numerischen 
		  Werte eines Tages auf einen einzigen Mittelwert reduziert. (impliziert 'average') <br>
          Optional kann als letzer Parameter "EXCLUDE=deviceRegExp1:ReadingRegExp1,deviceRegExp2:ReadingRegExp2,...." 
		  angegeben werden um device/reading Kombinationen von reduceLog auszuschließen. <br>
          Optional kann als letzer Parameter "INCLUDE=Database-deviceRegExp:Database-ReadingRegExp" angegeben werden um 
		  die auf die Datenbank ausgeführte SELECT-Abfrage einzugrenzen, was die RAM-Belastung verringert und die 
		  Performance erhöht. (Wildcards sind % und _) <br>
          </ul><br>
		  
    <code>set &lt;name&gt; reduceLogNbl &lt;n&gt; [average[=day]] [exclude=deviceRegExp1:ReadingRegExp1,deviceRegExp2:ReadingRegExp2,...]</code><br><br>
      <ul>Führt die gleiche Funktion wie "set &lt;name&gt; reduceLog" aus. Im Gegensatz zu reduceLog wird mit FHEM wird durch den Befehl reduceLogNbl nicht 
	      mehr blockiert da diese Funktion non-blocking implementiert ist ! <br>
          </ul><br>

    <code>set &lt;name&gt; userCommand &lt;validSqlStatement&gt;</code><br/><br/>
      <ul><b>BENUTZE DIESE FUNKTION NUR, WENN DU WIRKLICH (WIRKLICH!) WEISST, WAS DU TUST!!!</b><br/><br/>
          F&uuml;hrt einen beliebigen (!!!) sql Befehl in der Datenbank aus. Der Befehl und ein zur&uuml;ckgeliefertes Ergebnis werden in entsprechende Readings geschrieben.<br/>
      </ul><br>

  </ul><br>


  <a name="DbLogget"></a>
  <b>Get</b>
  <ul>
  <code>get &lt;name&gt; ReadingsVal&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &lt;device&gt; &lt;reading&gt; &lt;default&gt;</code><br/>
  <code>get &lt;name&gt; ReadingsTimestamp &lt;device&gt; &lt;reading&gt; &lt;default&gt;</code><br/>
  <br/>
  Liest einen einzelnen Wert aus der Datenbank, Benutzung und Syntax sind weitgehend identisch zu ReadingsVal() und ReadingsTimestamp().<br/>
  </ul>
  <br/>
  <br/>
  <ul>
    <code>get &lt;name&gt; &lt;infile&gt; &lt;outfile&gt; &lt;from&gt;
          &lt;to&gt; &lt;column_spec&gt; </code>
    <br><br>
    Liesst Daten aus der Datenbank. Wird durch die Frontends benutzt um Plots
    zu generieren ohne selbst auf die Datenank zugreifen zu m&ouml;ssen.
    <br>
    <ul>
      <li>&lt;in&gt;<br>
        Ein Parameter um eine Kompatibilität zum Filelog herzustellen.
        Dieser Parameter ist per default immer auf <code>-</code> zu setzen.<br>
        Folgende Ausprägungen sind zugelassen:<br>
        <ul>
          <li>current: die aktuellen Werte aus der Tabelle "current" werden gelesen.</li>
          <li>history: die historischen Werte aus der Tabelle "history" werden gelesen.</li>
          <li>-: identisch wie "history"</li>
        </ul> 
      </li>
	  
      <li>&lt;out&gt;<br>
        Ein Parameter um eine Kompatibilität zum Filelog herzustellen.
        Dieser Parameter ist per default immer auf <code>-</code> zu setzen um die
        Ermittlung der Daten aus der Datenbank für die Plotgenerierung zu prüfen.<br>
        Folgende Ausprägungen sind zugelassen:<br>
        <ul>
          <li>ALL: Es werden alle Spalten der Datenbank ausgegeben. Inclusive einer Überschrift.</li>
          <li>Array: Es werden alle Spalten der Datenbank als Hash ausgegeben. Alle Datensätze als Array zusammengefasst.</li>
          <li>INT: intern zur Plotgenerierung verwendet</li>
          <li>-: default</li>
        </ul>
      </li>
	  
      <li>&lt;from&gt; / &lt;to&gt;<br>
        Wird benutzt um den Zeitraum der Daten einzugrenzen. Es ist das folgende
        Zeitformat oder ein Teilstring davon zu benutzen:<br>
        <ul><code>YYYY-MM-DD_HH24:MI:SS</code></ul></li>
		
      <li>&lt;column_spec&gt;<br>
        Für jede column_spec Gruppe wird ein Datenset zurückgegeben welches
        durch einen Kommentar getrennt wird. Dieser Kommentar repräsentiert
        die column_spec.<br>
        Syntax: &lt;device&gt;:&lt;reading&gt;:&lt;default&gt;:&lt;fn&gt;:&lt;regexp&gt;<br>
        <ul>
          <li>&lt;device&gt;<br>
            Der Name des Devices. Achtung: Gross/Kleinschreibung beachten!<br>
            Es kann ein % als Jokerzeichen angegeben werden.</li>
          <li>&lt;reading&gt;<br>
            Das Reading des angegebenen Devices zur Datenselektion.<br>
            Es kann ein % als Jokerzeichen angegeben werden.<br>
            Achtung: Gross/Kleinschreibung beachten!
          </li>
          <li>&lt;default&gt;<br>
            Zur Zeit noch nicht implementiert.
          </li>
          <li>&lt;fn&gt;
            Angabe einer speziellen Funktion:
            <ul>
              <li>int<br>
                Ermittelt den Zahlenwert ab dem Anfang der Zeichenkette aus der
                Spalte "VALUE". Benutzt z.B. für Ausprägungen wie 10%.
              </li>
              <li>int&lt;digit&gt;<br>
                Ermittelt den Zahlenwert ab dem Anfang der Zeichenkette aus der
                Spalte "VALUE", inclusive negativen Vorzeichen und Dezimaltrenner.
                Benutzt z.B. für Auspägungen wie -5.7&deg;C.
              </li>
              <li>delta-h / delta-d<br>
                Ermittelt die relative Veränderung eines Zahlenwertes pro Stunde
                oder pro Tag. Wird benutzt z.B. für Spalten die einen
                hochlaufenden Zähler enthalten wie im Falle für ein KS300 Regenzähler
                oder dem 1-wire Modul OWCOUNT.
              </li>
              <li>delta-ts<br>
                Ermittelt die vergangene Zeit zwischen dem letzten und dem aktuellen Logeintrag
                in Sekunden und ersetzt damit den originalen Wert.
              </li>
            </ul></li>
            <li>&lt;regexp&gt;<br>
              Diese Zeichenkette wird als Perl Befehl ausgewertet. Die regexp wird vor dem angegebenen &lt;fn&gt; Parameter ausgef&ouml;hrt.
              <br>
              Bitte zur Beachtung: Diese Zeichenkette darf keine Leerzeichen
              enthalten da diese sonst als &lt;column_spec&gt; Trennung
              interpretiert werden und alles nach dem Leerzeichen als neue
              &lt;column_spec&gt; gesehen wird.<br>
              <b>Schlüsselw&ouml;rter</b>
              <li>$val ist der aktuelle Wert die die Datenbank für ein Device/Reading ausgibt.</li>
              <li>$ts ist der aktuelle Timestamp des Logeintrages.</li>
              <li>Wird als $val das Schlüsselwort "hide" zurückgegeben, so wird dieser Logeintrag nicht
                  ausgegeben, trotzdem aber f&ouml;r die Zeitraumberechnung verwendet.</li>
              <li>Wird als $val das Schlüsselwort "ignore" zurückgegeben, so wird dieser Logeintrag
                  nicht f&ouml;r eine Folgeberechnung verwendet.</li>
            </li>
        </ul></li>
		
      </ul>
    <br><br>
    <b>Beispiele:</b>
      <ul>
        <li><code>get myDbLog - - 2012-11-10 2012-11-20 KS300:temperature</code></li>
        <li><code>get myDbLog current ALL - - %:temperature</code></li><br>
            Damit erhält man alle aktuellen Readings "temperature" von allen in der DB geloggten Devices.
            Achtung: bei Nutzung von Jokerzeichen auf die history-Tabelle kann man sein FHEM aufgrund langer Laufzeit lahmlegen!
        <li><code>get myDbLog - - 2012-11-10_10 2012-11-10_20 KS300:temperature::int1</code><br>
           gibt Daten aus von 10Uhr bis 20Uhr am 10.11.2012</li>
        <li><code>get myDbLog - all 2012-11-10 2012-11-20 KS300:temperature</code></li>
        <li><code>get myDbLog - - 2012-11-10 2012-11-20 KS300:temperature KS300:rain::delta-h KS300:rain::delta-d</code></li>
        <li><code>get myDbLog - - 2012-11-10 2012-11-20 MyFS20:data:::$val=~s/(on|off).*/$1eq"on"?1:0/eg</code><br>
           gibt 1 zur&ouml;ck f&ouml;r alle Ausprägungen von on* (on|on-for-timer etc) und 0 f&ouml;r alle off*</li>
        <li><code>get myDbLog - - 2012-11-10 2012-11-20 Bodenfeuchte:data:::$val=~s/.*B:\s([-\.\d]+).*/$1/eg</code><br>
           Beispiel von OWAD: Ein Wert wie z.B.: <code>"A: 49.527 % B: 66.647 % C: 9.797 % D: 0.097 V"</code><br>
           und die Ausgabe ist für das Reading B folgende: <code>2012-11-20_10:23:54 66.647</code></li>
        <li><code>get DbLog - - 2013-05-26 2013-05-28 Pumpe:data::delta-ts:$val=~s/on/hide/</code><br>
           Realisierung eines Betriebsstundenzählers.Durch delta-ts wird die Zeit in Sek zwischen den Log-
           einträgen ermittelt. Die Zeiten werden bei den on-Meldungen nicht ausgegeben welche einer Abschaltzeit 
           entsprechen w&ouml;rden.</li>
      </ul>
    <br><br>
  </ul>

  <b>Get</b> für die Nutzung von webcharts
  <ul>
    <code>get &lt;name&gt; &lt;infile&gt; &lt;outfile&gt; &lt;from&gt;
          &lt;to&gt; &lt;device&gt; &lt;querytype&gt; &lt;xaxis&gt; &lt;yaxis&gt; &lt;savename&gt; </code>
    <br><br>
    Liest Daten aus der Datenbank aus und gibt diese in JSON formatiert aus. Wird für das Charting Frontend genutzt
    <br>

    <ul>
      <li>&lt;name&gt;<br>
        Der Name des definierten DbLogs, so wie er in der fhem.cfg angegeben wurde.</li>
      <li>&lt;in&gt;<br>
        Ein Dummy Parameter um eine Kompatibilität zum Filelog herzustellen.
        Dieser Parameter ist immer auf <code>-</code> zu setzen.</li>
      <li>&lt;out&gt;<br>
        Ein Dummy Parameter um eine Kompatibilität zum Filelog herzustellen. 
        Dieser Parameter ist auf <code>webchart</code> zu setzen um die Charting Get Funktion zu nutzen.
      </li>
      <li>&lt;from&gt; / &lt;to&gt;<br>
        Wird benutzt um den Zeitraum der Daten einzugrenzen. Es ist das folgende
        Zeitformat zu benutzen:<br>
        <ul><code>YYYY-MM-DD_HH24:MI:SS</code></ul></li>
      <li>&lt;device&gt;<br>
        Ein String, der das abzufragende Device darstellt.</li>
      <li>&lt;querytype&gt;<br>
        Ein String, der die zu verwendende Abfragemethode darstellt. Zur Zeit unterstützte Werte sind: <br>
          <code>getreadings</code> um für ein bestimmtes device alle Readings zu erhalten<br>
          <code>getdevices</code> um alle verfügbaren devices zu erhalten<br>
          <code>timerange</code> um Chart-Daten abzufragen. Es werden die Parameter 'xaxis', 'yaxis', 'device', 'to' und 'from' benötigt<br>
          <code>savechart</code> um einen Chart unter Angabe eines 'savename' und seiner zugehörigen Konfiguration abzuspeichern<br>
          <code>deletechart</code> um einen zuvor gespeicherten Chart unter Angabe einer id zu löschen<br>
          <code>getcharts</code> um eine Liste aller gespeicherten Charts zu bekommen.<br>
          <code>getTableData</code> um Daten aus der Datenbank abzufragen und in einer Tabelle darzustellen. Benötigt paging Parameter wie start und limit.<br>
          <code>hourstats</code> um Statistiken für einen Wert (yaxis) für eine Stunde abzufragen.<br>
          <code>daystats</code> um Statistiken für einen Wert (yaxis) für einen Tag abzufragen.<br>
          <code>weekstats</code> um Statistiken für einen Wert (yaxis) für eine Woche abzufragen.<br>
          <code>monthstats</code> um Statistiken für einen Wert (yaxis) für einen Monat abzufragen.<br>
          <code>yearstats</code> um Statistiken für einen Wert (yaxis) für ein Jahr abzufragen.<br>
      </li>
      <li>&lt;xaxis&gt;<br>
        Ein String, der die X-Achse repräsentiert</li>
      <li>&lt;yaxis&gt;<br>
         Ein String, der die Y-Achse repräsentiert</li>
      <li>&lt;savename&gt;<br>
         Ein String, unter dem ein Chart in der Datenbank gespeichert werden soll</li>
      <li>&lt;chartconfig&gt;<br>
         Ein jsonstring der den zu speichernden Chart repräsentiert</li>
      <li>&lt;pagingstart&gt;<br>
         Ein Integer um den Startwert für die Abfrage 'getTableData' festzulegen</li>
      <li>&lt;paginglimit&gt;<br>
         Ein Integer um den Limitwert für die Abfrage 'getTableData' festzulegen</li>
      </ul>
    <br><br>
    Beispiele:
      <ul>
        <li><code>get logdb - webchart "" "" "" getcharts</code><br>
            Liefert alle gespeicherten Charts aus der Datenbank</li>
        <li><code>get logdb - webchart "" "" "" getdevices</code><br>
            Liefert alle verfügbaren Devices aus der Datenbank</li>
        <li><code>get logdb - webchart "" "" ESA2000_LED_011e getreadings</code><br>
            Liefert alle verfügbaren Readings aus der Datenbank unter Angabe eines Gerätes</li>
        <li><code>get logdb - webchart 2013-02-11_00:00:00 2013-02-12_00:00:00 ESA2000_LED_011e timerange TIMESTAMP day_kwh</code><br>
            Liefert Chart-Daten, die auf folgenden Parametern basieren: 'xaxis', 'yaxis', 'device', 'to' und 'from'<br>
            Die Ausgabe erfolgt als JSON, z.B.: <code>[{'TIMESTAMP':'2013-02-11 00:10:10','VALUE':'0.22431388090756'},{'TIMESTAMP'.....}]</code></li>
        <li><code>get logdb - webchart 2013-02-11_00:00:00 2013-02-12_00:00:00 ESA2000_LED_011e savechart TIMESTAMP day_kwh tageskwh</code><br>
            Speichert einen Chart unter Angabe eines 'savename' und seiner zugehörigen Konfiguration</li>
        <li><code>get logdb - webchart "" "" "" deletechart "" "" 7</code><br>
            Löscht einen zuvor gespeicherten Chart unter Angabe einer id</li>
      </ul>
    <br><br>
  </ul>

  <a name="DbLogattr"></a>
  <b>Attribute</b>

  <ul><b>asyncMode</b>
    <ul>
	  <code>attr &lt;device&gt; asyncMode [1|0]
	  </code><br>
	  
      Dieses Attribut stellt den Arbeitsmodus von DbLog ein. Im asynchronen Modus (asyncMode=1), werden die zu speichernden Events zunächst in Speicher
	  gecacht. Nach Ablauf der Synchronisationszeit (Attribut syncInterval) oder bei Erreichen der maximalen Anzahl der Datensätze im Cache
	  (Attribut cacheLimit) werden die gecachten Events im Block in die Datenbank geschrieben.
	  Ist die Datenbank nicht verfügbar, werden die Events weiterhin im Speicher gehalten und nach Ablauf des Syncintervalls in die Datenbank
	  geschrieben falls sie dann verfügbar ist. <br>
	  Im asynchronen Mode werden die Daten nicht blockierend mit einem separaten Hintergrundprozess in die Datenbank geschrieben.
	  Det Timeout-Wert für diesen Hintergrundprozess kann mit dem Attribut "timeout" (Default 120s) eingestellt werden.
	  Im synchronen Modus (Normalmodus) werden die Events nicht gecacht und sofort in die Datenbank geschrieben. Ist die Datenbank nicht 
	  verfügbar gehen sie verloren.<br>
    </ul>
  </ul>
  <br>

  <ul><b>cacheEvents</b>
    <ul>
	  <code>attr &lt;device&gt; cacheEvents [2|1|0]
	  </code><br>
	  <ul>
      <li>cacheEvents=1: es werden Events für das Reading CacheUsage erzeugt wenn ein Event zum Cache hinzugefügt wurde. </li>
	  <li>cacheEvents=2: es werden Events für das Reading CacheUsage erzeugt wenn im asynchronen Mode der Schreibzyklus in die 
	                     Datenbank beginnt. CacheUsage enthält zu diesem Zeitpunkt die Anzahl der in die Datenbank zu schreibenden
						 Datensätze. </li><br>
	  </ul>
    </ul>
  </ul>
  <br>
  
  <ul><b>cacheLimit</b>
     <ul>
	   <code>
	   attr &lt;device&gt; cacheLimit &lt;n&gt; 
	   </code><br>
	 
       Im asynchronen Logmodus wird der Cache in die Datenbank weggeschrieben und geleert wenn die Anzahl &lt;n&gt; Datensätze
       im Cache erreicht ist (Default: 500). Der Timer des asynchronen Logmodus wird dabei neu auf den Wert des Attributs "syncInterval" 
       gesetzt. <br>
     </ul>
  </ul>
  <br>
  
  <ul><b>colEvent</b>
     <ul>
	   <code>
	   attr &lt;device&gt; colEvent &lt;n&gt; 
	   </code><br>
	 
	   Die Feldlänge für das DB-Feld EVENT wird userspezifisch angepasst. Mit dem Attribut kann der Default-Wert im Modul
	   verändert werden wenn die Feldlänge in der Datenbank manuell geändert wurde. Mit colEvent=0 wird das Datenbankfeld 
	   EVENT nicht gefüllt. <br>
	   <b>Hinweis:</b> <br> 
	   Mit gesetztem Attribut gelten alle Feldlängenbegrenzungen auch für SQLite DB wie im Internal COLUMNS angezeigt !  <br>
     </ul>
  </ul>
  <br>
  
  <ul><b>colReading</b>
     <ul>
	   <code>
	   attr &lt;device&gt; colReading &lt;n&gt; 
	   </code><br>
	 
	   Die Feldlänge für das DB-Feld READING wird userspezifisch angepasst. Mit dem Attribut kann der Default-Wert im Modul
	   verändert werden wenn die Feldlänge in der Datenbank manuell geändert wurde. Mit colReading=0 wird das Datenbankfeld 
	   READING nicht gefüllt. <br>
	   <b>Hinweis:</b> <br>
	   Mit gesetztem Attribut gelten alle Feldlängenbegrenzungen auch für SQLite DB wie im Internal COLUMNS angezeigt !  <br>
     </ul>
  </ul>
  <br>
  
  <ul><b>colValue</b>
     <ul>
	   <code>
	   attr &lt;device&gt; colValue &lt;n&gt; 
	   </code><br>
	 
	   Die Feldlänge für das DB-Feld VALUE wird userspezifisch angepasst. Mit dem Attribut kann der Default-Wert im Modul
	   verändert werden wenn die Feldlänge in der Datenbank manuell geändert wurde. Mit colValue=0 wird das Datenbankfeld 
	   VALUE nicht gefüllt. <br>
	   <b>Hinweis:</b> <br>
	   Mit gesetztem Attribut gelten alle Feldlängenbegrenzungen auch für SQLite DB wie im Internal COLUMNS angezeigt !  <br>
     </ul>
  </ul>
  <br>
  
  <ul><b>DbLogType</b>
     <ul>
	   <code>
	   attr &lt;device&gt; DbLogType [Current|History|Current/History]
	   </code><br>
	 
       Dieses Attribut legt fest, welche Tabelle oder Tabellen in der Datenbank genutzt werden sollen. Ist dieses Attribut nicht gesetzt, wird
       per default die Tabelle <i>history</i> verwendet. <br>
	   <b>Hinweis:</b> <br>
	   Die Current-Tabelle muß genutzt werden um eine Device:Reading-DropDownliste zur Erstellung eines 
	   SVG-Plots zu erhalten.   <br>
     </ul>
  </ul>
  <br>
  
  <ul><b>DbLogSelectionMode</b>
    <ul>
	  <code>
	  attr &lt;device&gt; DbLogSelectionMode [Exclude|Include|Exclude/Include]
	  </code><br>
      
	  Dieses, fuer DbLog-Devices spezifische Attribut beeinflußt, wie die Device-spezifischen Attributes
      DbLogExclude und DbLogInclude (s.u.) ausgewertet werden.<br>
      Fehlt dieses Attribut, wird dafuer "Exclude" als Default angenommen. <br>
   
      <ul>
        <li>Exclude: DbLog verhaelt sich wie bisher auch, alles was ueber die RegExp im DEF angegeben ist, wird geloggt, bis auf das,
                     was ueber die RegExp in DbLogExclude ausgeschlossen wird<br>
                     Das Attribut DbLogInclude wird in diesem Fall nicht beruecksichtigt</li>
        <li>Include: Es wird nur das geloggt was ueber die RegExp in DbLogInclude eingeschlossen wird.<br>
                     Das Attribut DbLogExclude wird in diesem Fall ebenso wenig beruecksichtigt wie die Regex im DEF. </li>
        <li>Exclude/Include: Funktioniert im Wesentlichen wie "Exclude", nur das sowohl DbLogExclude als auch DbLogInclude
                             geprueft werden. Readings die durch DbLogExclude zwar ausgeschlossen wurden, mit DbLogInclude aber wiederum eingeschlossen werden,
                             werden somit dennoch geloggt. </li>
      </ul>
    </ul>
  </ul>
  <br>
  
  <ul><b>DbLogInclude</b>
    <ul>
      <code>
      attr &lt;device&gt; DbLogInclude regex:MinInterval,[regex:MinInterval] ...
      </code><br>
      
	  Wenn DbLog genutzt wird, wird in allen Devices das Attribut <i>DbLogInclude</i> propagiert. 
	  DbLogInclude funktioniert im Endeffekt genau wie DbLogExclude, ausser dass eben readings mit diesen RegExp 
	  in das Logging eingeschlossen werden koennen, statt ausgeschlossen.
      Siehe dazu auch das DbLog-Device-Spezifische Attribut DbLogSelectionMode, das beeinflußt wie
      DbLogExclude und DbLogInclude ausgewertet werden. <br>

	  <b>Beispiel</b> <br>
      <code>attr MyDevice1 DbLogInclude .*</code> <br>
      <code>attr MyDevice2 DbLogInclude state,(floorplantext|MyUserReading):300,battery:3600</code>
    </ul>
  </ul>
  <br>
  
  <ul><b>DbLogExclude</b>
    <ul>
      <code>
      attr &lt;device&gt; DbLogExclude regex:MinInterval,[regex:MinInterval] ...
      </code><br>
    
      Wenn DbLog genutzt wird, wird in alle Devices das Attribut <i>DbLogExclude</i> propagiert. 
	  Der Wert des Attributes wird als Regexp ausgewertet und schliesst die damit matchenden Readings von einem Logging aus. 
	  Einzelne Regexp werden durch Kommata getrennt. Ist MinIntervall angegeben, so wird der Logeintrag nur
      dann nicht geloggt, wenn das Intervall noch nicht erreicht und der Wert des Readings sich nicht verändert hat. <br>
    
	  <b>Beispiel</b> <br>
      <code>attr MyDevice1 DbLogExclude .*</code> <br>
      <code>attr MyDevice2 DbLogExclude state,(floorplantext|MyUserReading):300,battery:3600</code>
    </ul>
  </ul>
  <br>
  
  <ul><b>excludeDevs</b>
     <ul>
	   <code>
	   attr &lt;device&gt; excludeDevs &lt;device1&gt;,&lt;device2&gt;,&lt;device..&gt; 
	   </code><br>
      
	   Die Devices "device1", "device2" bis "device.." werden vom Logging in der Datenbank ausgeschlossen. Diese Attribut wirkt nur wenn
       im Define des DbLog-Devices ".*:.*" (d.h. alle Devices werden geloggt) angegeben wurde. Dadurch können Devices explizit ausgeschlossen
	   werden anstatt alle zu loggenden Devices im Define einzuschließen (z.B. durch den String (device1|device2|device..):.* usw.). 
	   Die auszuschließenden Devices werden als Regex ausgewertet. <br>
	   
	  <b>Beispiel</b> <br>
      <code>
	  attr &lt;device&gt; excludeDevs global,Log.*,Cam.*
	  </code><br>
	  # Es werden die Devices global bzw. Devices beginnend mit "Log" oder "Cam" vom Datenbanklogging ausgeschlossen. <br>
     </ul>
  </ul>
  <br>

  <ul><b>shutdownWait</b>
     <ul>
	   <code>
	   attr &lt;device&gt; shutdownWait <n>
	   </code><br>
	   
       FHEM wartet während des shutdowns fuer n Sekunden, um die Datenbank korrekt zu beenden<br/>
     </ul>
  </ul>
  <br>
  
  <ul><b>noNotifyDev</b>
     <ul>
	   <code>
	   attr &lt;device&gt; noNotifyDev [1|0]
	   </code><br>
	   
       Erzwingt dass NOTIFYDEV nicht gesetzt und somit nicht verwendet wird .<br>
     </ul>
  </ul>
  <br>
  
  <ul><b>showproctime</b>
    <ul>
	  <code>attr &lt;device&gt; showproctime [1|0]
	  </code><br>
	  
      Wenn gesetzt, zeigt das Reading "sql_processing_time" die benötigte Abarbeitungszeit (in Sekunden) für die SQL-Ausführung der
	  durchgeführten Funktion. Dabei wird nicht ein einzelnes SQL-Statement, sondern die Summe aller notwendigen SQL-Abfragen innerhalb der
	  jeweiligen Funktion betrachtet. Das Reading "background_processing_time" zeigt die im Kindprozess BlockingCall verbrauchte Zeit.<br>
	  
    </ul>
  </ul>
  <br>
  
  <ul><b>showNotifyTime</b>
    <ul>
	  <code>attr &lt;device&gt; showNotifyTime [1|0]
	  </code><br>
	  
      Wenn gesetzt, zeigt das Reading "notify_processing_time" die benötigte Abarbeitungszeit (in Sekunden) für die 
	  Abarbeitung der DbLog Notify-Funktion. Das Attribut ist für Performance Analysen geeignet und hilft auch die Unterschiede
	  im Zeitbedarf bei der Umschaltung des synchronen in den asynchronen Modus festzustellen. <br>
	  
    </ul>
  </ul>
  <br>
  
  <ul><b>syncEvents</b>
    <ul>
	  <code>attr &lt;device&gt; syncEvents [1|0]
	  </code><br>
	  
      es werden Events für Reading NextSync erzeugt. <br>
    </ul>
  </ul>
  <br>
  
  <ul><b>syncInterval</b>
    <ul>
	  <code>attr &lt;device&gt; syncInterval &lt;n&gt;
	  </code><br>
	  
      Wenn DbLog im asynchronen Modus betrieben wird (Attribut asyncMode=1), wird mit diesem Attribut das Intervall in Sekunden zur Speicherung
	  der im Speicher gecachten Events in die Datenbank eingestellt. Der Defaultwert ist 30 Sekunden. <br>
	  
    </ul>
  </ul>
  <br>
  
  <ul><b>suppressUndef</b>
    <ul>
	  <code>attr &lt;device&gt; ignoreUndef <n>
	  </code><br>
      Unterdrueckt alle undef Werte die durch eine Get-Anfrage zb. Plot aus der Datenbank selektiert werden <br>

	  <b>Beispiel</b> <br>
      <code>#DbLog eMeter:power:::$val=($val>1500)?undef:$val</code>
    </ul>
  </ul>
  <br>
  
  <ul><b>timeout</b>
    <ul>
	  <code>
	  attr &lt;device&gt; timeout <n>
	  </code><br>
      Setzt den Timeout-Wert für den Schreibzyklus in die Datenbank im asynchronen Modus (default 1800s). <br>

    </ul>
  </ul>
  <br>

  <ul><b>verbose4Devs</b>
     <ul>
	   <code>
	   attr &lt;device&gt; verbose4Devs &lt;device1&gt;,&lt;device2&gt;,&lt;device..&gt; 
	   </code><br>
      
	   Mit verbose Level 4 werden nur Ausgaben bezüglich der in diesem Attribut aufgeführten Devices im Logfile protokolliert. Ohne dieses 
       Attribut werden mit verbose 4 Ausgaben aller relevanten Devices im Logfile protokolliert.
	   Die angegebenen Devices werden als Regex ausgewertet. <br>
	   
	  <b>Beispiel</b> <br>
      <code>
	  attr &lt;device&gt; verbose4Devs sys.*,.*5000.*,Cam.*,global
	  </code><br>
	  # Es werden Devices beginnend mit "sys", "Cam" bzw. Devices die "5000" enthalten und das Device "global" protokolliert falls verbose=4
	  eingestellt ist. <br>
     </ul>
  </ul>
  <br>
  
</ul>

=end html_DE
=cut
