package Loggator::DB::Main::Data;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('data');
__PACKAGE__->add_columns(qw/ dataid name datatype datakind log /);
__PACKAGE__->set_primary_key('dataid');
#__PACKAGE__->has_one('datatype' => 'Loggator::DB::Main::DataType');
#__PACKAGE__->has_one('datakind' => 'Loggator::DB::Main::DataKind');
__PACKAGE__->belongs_to('datatype' => 'Loggator::DB::Main::DataType');
__PACKAGE__->belongs_to('datakind' => 'Loggator::DB::Main::DataKind');
__PACKAGE__->belongs_to('log'    => 'Loggator::DB::Main::Log');

1;
