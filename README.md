### SYSTEM_INIT

    bash system_boot.sh
  
### MYSQL_INSTALL

    bash mysql_install.sh all
  
### PHP_INSTALL

    bash php_install.sh all
 
Installation gd2 need to add a piece of code

In this file ./gd_io.h

```
  typedef struct gdIOCtx
  {
    int (*getC) (struct gdIOCtx *); 
    int (*getBuf) (struct gdIOCtx *, void *, int);

    void (*putC) (struct gdIOCtx *, int);
    int (*putBuf) (struct gdIOCtx *, const void *, int);

    /* seek must return 1 on SUCCESS, 0 on FAILURE. Unlike fseek! */
    int (*seek) (struct gdIOCtx *, const int);

    long (*tell) (struct gdIOCtx *); 

    void (*gd_free) (struct gdIOCtx *); 

    void (*data);     
   
  }
  
  void (*data); as new

```
### NGINX_INSTALL
bash nginx_install.sh all
