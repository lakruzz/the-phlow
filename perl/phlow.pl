#!/usr/bin/perl
require 5.000;
use strict;                # http://perldoc.perl.org/strict.html
use Carp;                  # http://perldoc.perl.org/Carp.html
use Cwd;                   # http://perldoc.perl.org/Cwd.html

# File version
our $VERSION    = "1.0";                             #major.minor
our $PATCH      = "1";                               #patch

use Getopt::Long;          # http://perldoc.perl.org/Getopt/Long.html
use Pod::Usage;            # http://perldoc.perl.org/Pod/Usage.html
use File::Basename;        # http://perldoc.perl.org/File/Basename.html
use lib dirname(__FILE__); # Assume local modules are in sub folders relative to this script

# Define the global variables that are used to cache the value of our options
our (
	$Sw_squash, $Sw_integration_branch, $Sw_worker_branch, $Remote
);

# TODO read this from git context, it might not actually be 'origin'.
$Remote = 'origin';

GetOptions(
  (
    "squash!"              => \$Sw_squash,
    "integration=s"        => \$Sw_integration_branch,
    "worker=s"             => \$Sw_worker_branch,
		"help"                 => sub { pod2usage(-exitval => 0, -verbose => 1) },
    "man"                  => sub { pod2usage(-exitval => 0, -verbose => 2) }
	)
) || pod2usage(-exitval => 1, -verbose => 0);

validate_context();
merge( {
  from   => $Sw_worker_branch,
	to     => $Sw_integration_branch,
	squash => $Sw_squash,
	rebase => 1 }
);

exit(0);

# end of main loop

=head1 FUNCTIONS

=cut

sub validate_context(){

=head2 validate_context

B<Input:> void

The function checks that all options are applied correct and unambiguously and it check that the execution takes place in a valid context. The test operates on the global variables that was used to cache the parameters. (by convention all variables named C<$Sw_...>).
=cut

  # Are options applied correctly?
  defined($Sw_squash) || do { $Sw_squash = 1 };
	defined($Sw_integration_branch) || pod2usage(-exitval => 0, -verbose => 1,
	  -message => "-integration branch is required");
	defined($Sw_worker_branch) || pod2usage(-exitval => 0, -verbose => 1,
	  -message => "-worker branch is required");

	#Are we in a git context? Testing both git environemnt, local clone and connection to origin in one go
	`git branch --remote 2>&1`;	$? && croak "Not in a valid git context";

	# Are we at the toplevel?
	my $git_toplevel = `git rev-parse --show-toplevel 2>&1`;chomp($git_toplevel);
	my $pwd = cwd();
	$git_toplevel eq $pwd || croak "Working directory ($pwd), must be the top-level in the git tree ($git_toplevel) at the time of execution";
};

sub merge( $ ){

=head2 merge

Will merge from one branch to another

B<Input:> $%options

A reference to hash, containing the options to operate from. Typically the reference will be defined as part of the function call itself.

B<Example:>

C<< merge( {from => 'ready/my-branch', to => 'master', squash =\> 1, rebase =\> 1} ); >>

=over

=item B<from> (string) I<[required]>

The branch to merge from

=item B<to> (string) I<[required]>

The branch to merge to

=item B<squash> (boolean) I<[optional]>

Indicates if more than one commit is allowed, or if multiple commits should be squashed before the merge.

Default is 1 (true)

=item B<rebase> (boolean) I<[optional]>

Indicates if the from branch should be rebased against the to branch before the merge.

Default is 1 (true)

=back

=cut

	# read the hase reference, and dereference it.
	my $options_ref = shift; my %options = %$options_ref;

	defined( $options{'from'} ) && defined( $options{'to'} )
		|| croak "Both 'from' and 'to' is required in merge()";

  # Set read the optional args, or set to defaults
	defined( $options{'squash'}) || do{ $options{'squash'} = 1 };
	defined( $options{'rebase'}) || do{ $options{'rebase'} = 1 };

  system("git checkout $options{'from'}"); $? && croak ;

	if ($options{'rebase'}){
		system("git pull --rebase $Remote $options{'to'}"); $? && croak;
	};



}

__END__

# Below is all the POD documentation (http://perldoc.perl.org/perlpod.html).
# The interpreter won't go beyond the __END__ specified above, so don't add more statemments below this point.

=pod

=head1 NAME

This script is related to "The Phlow" described in detail in L<A Praqmatic Workflow|http://www.praqma.com/stories/a-pragmatic-workflow/>

It provides the various features that are required to support automated integration of worker branches and hereby enable an automated pretested integration strategy on CI serveres.

=over

=item B<Copyright:>

Praqma, 2017, L<www.praqma.com|http://www.praqma.com>

=item B<License:>

M.I.T.

=item B<Repository:>

L<github.com/praqma/the-phlow|http://github.com/praqma/the-phlow>

=item Support:

Use the L<issue system|http://github.com/praqma/the-phlow/issues> in the repo

=back

=head1 SYNOPSIS

 phlow -integration branch -worker branch [-[no]squash]
 phlow -help | -man

=head1 OPTIONS

=over 8

=item B<-worker branch>

branch is the source of your commit.

=item B<-integration branch>

branch is the target for your integration.

=item B<-[no]squash>

Will squash commits if source contains more than one new commit. -squash is default. -nosquash will integrate all commets to the target branch as is.

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION


=cut
