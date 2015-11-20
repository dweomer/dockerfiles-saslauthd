# Cyrus SASL saslauthd on Alpine Linux

The default cyrus-sasl package for Alpine Linux didn't support LDAP so I built this image which installs it from source.

## Using the `shadow` authentication mechanism:

### Start the daemon

```
docker run -d \
    --name saslauthd \
    --volume /etc/shadow:/etc/shadow:ro \
    --volume /etc/passwd:/etc/passwd:ro \
    dweomer/saslauthd -a shadow -d 1
```

## Starting the daemon configured with the (default) `ldap` authentication mechanism:

### Setup `saslauthd.conf` for an Active Directory instance running at 1.2.3.4:

```
ldap_servers: ldap://1.2.3.4/
ldap_search_base: DC=example,DC=com
ldap_filter: (&(objectClass=Person)(sAMAccountName=%u))
ldap_bind_dn: <Bind RDN>,ou=Service Accounts,DC=example,DC=com
ldap_password: <password>
```

### Start the daemon

```
docker run -d \
    --name saslauthd \
    --volume $(pwd)/saslauthd.conf:/etc/saslauthd.conf:ro \
    dweomer/saslauthd
```

## Verify that you can authenticate as expected:

```
docker run -it --rm \
    --entrypoint /usr/sbin/testsaslauthd \
    --volumes-from saslauthd \
    dweomer/saslauthd -u <your local username> -p <your password>
```
