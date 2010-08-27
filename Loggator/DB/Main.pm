package Loggator::DB::Main;
use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_classes(qw( LogEntry Log DataType DataKind Data Data_Bool Data_Int Data_Float Data_Timestamp Data_Date Data_Duration Data_String Data_Text ) );

1;

