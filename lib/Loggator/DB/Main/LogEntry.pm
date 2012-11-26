package Loggator::DB::Main::LogEntry;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('logentry');
__PACKAGE__->add_columns(qw/ logentryid log timestamp /);
__PACKAGE__->set_primary_key('logentryid');
__PACKAGE__->belongs_to('log'           => 'Loggator::DB::Main::Log');
__PACKAGE__->has_many('data_bools'      => 'Loggator::DB::Main::Data_Bool');
__PACKAGE__->has_many('data_ints'       => 'Loggator::DB::Main::Data_Int');
__PACKAGE__->has_many('data_floats'     => 'Loggator::DB::Main::Data_Float');
__PACKAGE__->has_many('data_timestamps' => 'Loggator::DB::Main::Data_Timestamp');
__PACKAGE__->has_many('data_dates' => 'Loggator::DB::Main::Data_Date');
__PACKAGE__->has_many('data_durations'  => 'Loggator::DB::Main::Data_Duration');
__PACKAGE__->has_many('data_strings'    => 'Loggator::DB::Main::Data_String');
__PACKAGE__->has_many('data_texts'      => 'Loggator::DB::Main::Data_Text');

1;
