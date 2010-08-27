package Loggator::DB::Main::DataType;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('datatype');
__PACKAGE__->add_columns(qw/ datatypeid type /);
__PACKAGE__->set_primary_key('datatypeid');
__PACKAGE__->has_one('data' => 'Loggator::DB::Main::Data');

