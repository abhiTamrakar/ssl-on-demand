# ssl-on-demand
SSL script used for on demand certificate generation and validation.

## Automate SSL Expiry Checks

The script provides a utility to scan all certificates from multiple directories on hosts and generate reports in various format including prometheus metrics.

```bash

  USAGE: SSLexpiryPredictions.sh -[cdewolh]

  DESCRIPTION: This script predicts and prints the expiring SSL certificates based on the end date.

  OPTIONS:

  -c|   sets the value for configuration file which has server:port or host:port details.

  -d|   sets the value of directory containing the certificate files in crt or pem format.

  -e|   sets the value of certificate extension [crt, pem], default: crt

  -w|   sets the value for output format of the script [table, csv, json, prometheus], default: table

  -o|   write output to a file.

  -l|   sets the log level [info, debug, error, warn], default: info

  -h|   prints this help and exit.

SYNTAX:

# provide one or more directories to scan ssl certificates

$ ./SSLexpiryPredictions.sh -d /path/to/certificates/dir -e pem

OR

$ ./SSLexpiryPredictions.sh -d /dir1,/dir2,/dir3 -e crt

OR

# create a file with server:port
cat <<EOF> servers.list
server1:port1
server2:port2
server3:port3
EOF
        
$ ./SSLexpiryPredictions.sh -c server.list
```

## **Examples:**

#### print prometheus metrics format
```bash
# HELP ssl_certificate_time_to_expire ssl certificate expiration time in days
# TYPE ssl_certificate_time_to_expire GAUGE
ssl_certificate_time_to_expire{commonname="soon expiring certificate",issuer="soon expiring certificate",serial="0D2CEA0E1E1CB32D028BD2EEAC42F5AB176BAD39"} 0.00
ssl_certificate_time_to_expire{commonname="expiring in a week certificate",issuer="expiring in a week certificate",serial="76A5B03E81DDDA4CA764D6534900CBE9FA00CD74"} 7.00
ssl_certificate_time_to_expire{commonname="example.com",issuer="example.com",serial="6B58FD18F9ED99155095113A828A581FB84C854B"} 364.00
ssl_certificate_time_to_expire{commonname="longer validity certificate",issuer="longer validity certificate",serial="65D7EED53C03D83D1A418C3B9A20FE6732891325"} 1199.00
ssl_certificate_time_to_expire{commonname="certificate4",issuer="certificate4",serial="7027E688672B4E49B729737848EEDC73EAC659F3"} 99.00
# HELP ssl_certificates_scanned_total total ssl certificates scanned
# TYPE ssl_certificates_scanned_total COUNTER
ssl_certificates_scanned_total 5
# HELP ssl_certificates_expired_total total ssl certificates expired
# TYPE ssl_certificates_expired_total COUNTER
ssl_certificates_expired_total 1
```

#### print table format

```bash
------------------------------------------------------------------------------------------
                                     List of expiring SSL certificates
------------------------------------------------------------------------------------------
QUERY         COMMONNAME                      ISSUER                          SERIAL                                    TIMETOEXPIRE
certificate2  soon expiring certificate       soon expiring certificate       0D2CEA0E1E1CB32D028BD2EEAC42F5AB176BAD39  0
certificate3  expiring in a week certificate  expiring in a week certificate  76A5B03E81DDDA4CA764D6534900CBE9FA00CD74  7
certificate4  certificate4                    certificate4                    7027E688672B4E49B729737848EEDC73EAC659F3  99
certificate   example.com                     example.com                     6B58FD18F9ED99155095113A828A581FB84C854B  364
certificate1  longer validity certificate     longer validity certificate     65D7EED53C03D83D1A418C3B9A20FE6732891325  1199
------------------------------------------------------------------------------------------

```
#### print csv format

```bash
query,commonname,issuer,serial,timetoexpire
certificate2,soon expiring certificate,soon expiring certificate,0D2CEA0E1E1CB32D028BD2EEAC42F5AB176BAD39,0
certificate3,expiring in a week certificate,expiring in a week certificate,76A5B03E81DDDA4CA764D6534900CBE9FA00CD74,7
certificate4,certificate4,certificate4,7027E688672B4E49B729737848EEDC73EAC659F3,99
certificate,example.com,example.com,6B58FD18F9ED99155095113A828A581FB84C854B,364
certificate1,longer validity certificate,longer validity certificate,65D7EED53C03D83D1A418C3B9A20FE6732891325,1199
```

#### print json format

```json
{
  "items": [
    {
      "certificate2": {
        "commonname": "soon expiring certificate",
        "issuer": "soon expiring certificate",
        "serial": "0D2CEA0E1E1CB32D028BD2EEAC42F5AB176BAD39",
        "days": 0
      }
    },
    {
      "certificate3": {
        "commonname": "expiring in a week certificate",
        "issuer": "expiring in a week certificate",
        "serial": "76A5B03E81DDDA4CA764D6534900CBE9FA00CD74",
        "days": 7
      }
    },
    {
      "certificate": {
        "commonname": "example.com",
        "issuer": "example.com",
        "serial": "6B58FD18F9ED99155095113A828A581FB84C854B",
        "days": 364
      }
    },
    {
      "certificate1": {
        "commonname": "longer validity certificate",
        "issuer": "longer validity certificate",
        "serial": "65D7EED53C03D83D1A418C3B9A20FE6732891325",
        "days": 1199
      }
    },
    {
      "certificate4": {
        "commonname": "certificate4",
        "issuer": "certificate4",
        "serial": "7027E688672B4E49B729737848EEDC73EAC659F3",
        "days": 99
      }
    }
  ]
}
```

## Automates CSR and private key creation.

```
Usage: 	genSSLcsr.sh [options] -[cdmshx]
  [-c (common name)]
  [-d (domain name)]
  [-s (SSL certificate subject)]
  [-p (password)]
  [-m (email address)] *(Experimental)
  [-r (remove pasphrase) default:true]
  [-h (help)]
  [-x (optional)]

[OPTIONS]
  -c|   Sets the value for common name.
        A valid common name is something that ends with 'xyz.com'

  -d|   Sets the domain name.

  -s|   Sets the subject to be applied to the certificates.
        '/C=country/ST=state/L=locality/O=organization/OU=organizationalunit/emailAddress=email'

  -p|   Sets the password for private key.

  -r|   Sets the value of remove passphrase.
        true:[default] passphrase will be removed from key.
        false: passphrase will not be removed and key wont get printed.

  -m|   Sets the mailing capability to the script.
        (Experimental at this time and requires a lot of work)

  -x|   Creates the certificate request and key but do not print on screen.
        To be used when script is used just to create the key and CSR with no need
        + to generate the certficate on the go.

  -h|   Displays the usage. No further functions are performed.

  Example: genSSLcsr.sh -c mywebsite.xyz.com -m myemail@mydomain.com
```
