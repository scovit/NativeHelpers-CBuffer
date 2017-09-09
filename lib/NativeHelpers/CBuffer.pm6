use NativeCall;

class CBuffer is repr('CPointer') is export { 
   my $t;
   my size_t $s;

   sub calloc(size_t $count, size_t $size --> Pointer) is native { }
   sub strncpy(Pointer $dst, Str $src, size_t $len --> CBuffer) is native { }
   sub memcpy_A(Pointer $dest, Blob:D $src, size_t $size --> Pointer) is native is symbol('memcpy') { }
   sub memcpy_B(Blob:D $dest, CBuffer $src, size_t $size --> Pointer) is native is symbol('memcpy') { }
   sub free(CBuffer $what) is native { }

   method new(size_t $size, :$init = Any, :$type = uint8) {
       $t = $type;
       $s = $size;
       my Pointer $ptr = calloc($s, nativesizeof($t));
       if (defined($init)) {
           given $init {
               when Str {
                   strncpy($ptr, $_, $size * nativesizeof($t));
               }
               when Blob {
                   memcpy_A($ptr, $_, .bytes min ($size * nativesizeof($t)) );
               }
               default {
                   die 'Expected Blob or Str initialization for CBuffer';
               }
           }
       }
       nativecast(CBuffer, $ptr);
   }

   method Blob(--> Blob) {
       my Blob[$t] $b = Blob[$t].new(0 xx $s);
       memcpy_B($b, self, $s * nativesizeof($t));
       $b;
   }

   method Pointer(--> Pointer) { nativecast(Pointer[$t], self) }

   method Str(--> Str) {
       do with self.Blob { .substr(0, .index("\0")) given .decode("ascii") };
   }

   method gist(--> Str) { self.Str; }

   submethod DESTROY { free(self); }
}

