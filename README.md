# ssl-on-demand
SSL script used for on demand certificate generation and validation.

## Automate SSL Expiry Checks

```

  USAGE: SSLexpiryPredictions.sh -[cdewh]

  DESCRIPTION: This script predicts the expiring SSL certificates based on the end date.

  OPTIONS:

  -c|   sets the value for configuration file which has server:port or host:port details.
        
  -d|   sets the value of directory containing the certificate files in crt or pem format.

  -e|   sets the value of certificate extention, e.g crt, pem, cert.
        crt: default [to be used with -d, if certificate file extention is other than .crt]

  -w|   sets the value for writing the script output to a file.

  -h|   prints this help and exit.
```

**Examples:**
> Create a file with list of all servers and their port numbers to make an ssl handshake.
```
cat > servers.list
         server1:port1
         server2:port2
         server3:port3
        (ctrl+d)
        
$ ./SSLexpiryPredictions.sh -c server.list
```

> Run the script by providing the certificate location and extention, incase, it is other than .crt. 

```
$ ./SSLexpiryPredictions.sh -d /path/to/certificates/dir -e pem

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
