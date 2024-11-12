=head1 NAME

AnnotateClinVar - a plugin for VEP that annotates the ClinVar database.

=head1 SYNOPSIS

vep -i input.vcf -o output.txt --fasta hg38.fa --plugin AnnotateClinVar,clinvar_file=/path/to/clinvar.vcf.gz,fields=CLNSIG,CLNDN,CLNSTAR

=head1 DESCRIPTION

This plugin can annotate ClinVar_CLNSIG, ClinVar_CLNREVSTAT, ClinVar_CLNDN, ClinVar_CLNHGVS, ClinVar_CLNSTAR

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

package AnnotateClinVar;

use strict;
use warnings;

sub new {
    my ($class, $clinvar_file, $fields) = @_;
    my $self = bless {}, $class;

    # 加载ClinVar数据文件
    $self->{clinvar_file} = $clinvar_file;
    $self->load_clinvar_data();

    # 将字段列表解析为数组，供后续注释使用
    $self->{fields} = [split /,/, $fields || "CLNSIG,CLNREVSTAT,CLNDN,CLNHGVS"];
    
    return $self;
}

sub feature_types {
    return ['VariationFeature'];
}

sub get_header_info {
    my ($self) = @_;
    my %header_info = (
        ClinVar_CLNSIG => "ClinVar clinical significance",
        ClinVar_CLNREVSTAT => "ClinVar review status",
        ClinVar_CLNDN => "ClinVar disease name",
        ClinVar_CLNHGVS => "ClinVar HGVS notation",
        ClinVar_CLNSTAR => "ClinVar star rating based on CLNREVSTAT",
    );

    # 仅返回用户指定的字段
    return { map { $_ => $header_info{$_} } @{$self->{fields}}, 'ClinVar_CLNSTAR' };
}

sub run {
    my ($self, $vf, $line_hash) = @_;
    my $clinvar_info = $self->query_clinvar($vf);

    # 检查ClinVar信息并根据用户指定字段进行注释
    if ($clinvar_info) {
        foreach my $field (@{$self->{fields}}) {
            $line_hash->{"ClinVar_$field"} = $clinvar_info->{$field} if exists $clinvar_info->{$field};
        }
        $line_hash->{ClinVar_CLNSTAR} = $clinvar_info->{StarRating};
    }

    return {};
}

# clinvar星级转换函数
sub clinvar_star {
    my ($self, $value) = @_;
    my %rating_mapping = (
        'guideline' => '4',
        'reviewed_by_expert_panel' => '3',
        '_multiple_submitters' => '2',
        '_single_submitter' => '1',
        'conflicting' => '1',
    );

    foreach my $key (keys %rating_mapping) {
        if (index($value, $key) != -1) {
            return $rating_mapping{$key};
        }
    }
    return ".";
}

sub load_clinvar_data {
    my ($self) = @_;
    # 加载ClinVar数据文件并将其解析为合适的数据结构
}

sub query_clinvar {
    my ($self, $vf) = @_;
    my %clinvar_info;

    # 根据变异位置和ClinVar文件精确匹配数据
    $clinvar_info{CLNSIG} = "某个临床意义"; # 示例值
    $clinvar_info{CLNREVSTAT} = "reviewed_by_expert_panel"; # 示例值
    $clinvar_info{CLNDN} = "疾病名称"; # 示例值
    $clinvar_info{CLNHGVS} = "HGVS注释"; # 示例值

    # 根据CLNREVSTAT转换星级
    $clinvar_info{StarRating} = $self->clinvar_star($clinvar_info{CLNREVSTAT});

    return \%clinvar_info;
}

1;

