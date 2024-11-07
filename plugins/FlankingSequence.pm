=head1 NAME

FlankingSequence - a plugin for VEP that annotates the surrounding sequence of a variant with [ref/alt] notation.

=head1 SYNOPSIS

  vep -i input.vcf -o output.txt --fasta hg38.fa --plugin FlankingSequence,10

=head1 DESCRIPTION

This plugin retrieves the sequence surrounding a variant, based on a specified number of flanking bases on either side. It inserts the variant in the format [ref/alt] in the middle of the sequence. The flanking length can be specified as a parameter.

=head1 PARAMETERS

This plugin takes one parameter, which specifies the number of bases to retrieve upstream and downstream of the variant. The default is 10 bases.

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

# FlankingSequence.pm
package FlankingSequence;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;

# 继承BaseVepPlugin
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    
    # 读取参数
    my $params = $self->params;
    $self->{flank_length} = $params->[0] || 10;  # 上下游长度，默认为10
    
    return $self;
}

sub feature_types {
    return ['Transcript'];
}

sub get_header_info {
    return {
        'FlankingSequence' => "Sequence surrounding the variant with [ref/alt] notation",
    };
}

sub run {
    my ($self, $tva) = @_;
    
    # 提取位置信息和变异信息
    my $vf = $tva->variation_feature;
    my $chrom = $vf->seq_region_name;
    my $pos = $vf->seq_region_start;
    my $ref = $vf->ref_allele_string;
    
    # 获取 alt 等位基因，确保只取第一个变异碱基
    my $alt = $vf->alt_alleles ? join(',', @{$vf->alt_alleles}) : '';
    if (!$alt) {
        warn "No alternative allele found for variant at $chrom:$pos\n";
        return {};
    }
    
    # 获取上下游序列
    my $flank_length = $self->{flank_length};
    my $slice = $vf->slice->sub_Slice($pos - $flank_length, $pos + $flank_length);
    my $flanking_seq = $slice ? $slice->seq : '';
    
    # 确认获取到的序列长度是否符合预期
    if (length($flanking_seq) < (2 * $flank_length + length($ref))) {
        warn "Sequence length insufficient for variant at $chrom:$pos\n";
        return {};
    }
    
    # 插入变异信息
    my $mutated_seq = substr($flanking_seq, 0, $flank_length) . "[$ref/$alt]" . substr($flanking_seq, $flank_length + length($ref));
    
    return {
        FlankingSequence => $mutated_seq,
    };
}

1;
