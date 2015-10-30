# PHP_INSTALL

安装gd2的时候需要增加一段代码

在./gd_io.h 这个文件中

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

void (*data); 为新增
