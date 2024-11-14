=head1 NAME

MissenseZscoreTranscript - a plugin for VEP that annotates variants with a Missense Z-score based on transcript IDs from a BED file.

=head1 SYNOPSIS

vep -i input.vcf -o output.txt --plugin MissenseZscoreTranscript,/path/to/bedfile.bed

=head1 DESCRIPTION

This plugin retrieves a Z-score for a given transcript ID from a provided BED file. The plugin will match the transcript ID (ignoring version numbers) in the VEP annotation with the 4th column of the BED file and retrieve the corresponding Z-score from the 14th column. The result is added to the annotation under the field "MissenseZscore".

=head1 PARAMETERS

This plugin takes one parameter, the path to a BED file, where:
  - The 4th column contains transcript IDs (e.g., ENST00000367770).
  - The 14th column contains the associated Z-score for missense mutations.

=head1 LICENSE

MIT License

Copyright (c) 2024 pzweuj

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 AUTHOR

pzweuj, pzweuj@live.com

=cut

package MissenseZscoreTranscript;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    
    my $bed_file = $self->params->[0];
    my $exact_match = $self->params->[1] || 0;
    
    die "错误：BED文件不存在！" unless -e $bed_file;
    
    open my $fh, '<', $bed_file or die "Could not open BED file: $!";
    
    $self->{z_scores} = {};
    $self->{exact_match} = $exact_match;
    
    while (<$fh>) {
        chomp;
        my @fields = split "\t";
        next unless scalar @fields >= 14;
        
        my $transcript_id;
        if ($exact_match) {
            $transcript_id = $fields[3];
        } else {
            ($transcript_id) = $fields[3] =~ /^([^.]+)/;
        }
        
        my $z_score = $fields[13];
        
        if (defined $transcript_id && defined $z_score) {
            $self->{z_scores}->{$transcript_id} = $z_score;
        }
    }
    close $fh;

    return $self;
}

sub run {
    my ($self, $variant) = @_;
    
    return {} unless defined $variant && defined $variant->{hgvs_transcript};
    
    my $transcript_id;
    if ($self->{exact_match}) {
        ($transcript_id) = $variant->{hgvs_transcript} =~ /^(NM_\d+\.\d+)(?::|$)/;
    } else {
        ($transcript_id) = $variant->{hgvs_transcript} =~ /^(NM_\d+)(?:\.\d+)?(?::|$)/;
    }
    
    return {} unless defined $transcript_id;
    
    my $z_score = $self->{z_scores}->{$transcript_id};
    return defined $z_score ? { MissenseZscore => $z_score } : {};
}

sub get_header_info {
    return {
        MissenseZscore => "Z-score for missense mutations based on transcript from BED file",
    };
}

1;
