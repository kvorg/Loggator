package Loggator::DB::Main::Log;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('log');
__PACKAGE__->add_columns(qw/ logid name file /);
__PACKAGE__->set_primary_key('logid');
__PACKAGE__->has_many('datas'      => 'Loggator::DB::Main::Data');
__PACKAGE__->has_many('logentrys' => 'Loggator::DB::Main::LogEntry');

1;
