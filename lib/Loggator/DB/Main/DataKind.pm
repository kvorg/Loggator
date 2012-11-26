package Loggator::DB::Main::DataKind;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('datakind');
__PACKAGE__->add_columns(qw/ datakindid kind /);
__PACKAGE__->set_primary_key('datakindid');
__PACKAGE__->has_one('data' => 'Loggator::DB::Main::Data');

