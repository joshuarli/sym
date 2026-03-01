#!/usr/bin/env bash

set -e
die () { >&2 printf %s\\n "$1"; exit 1; }

tmp="$(mktemp -d)" || die 'mktemp failed'
trap "rm -rf ${tmp}" EXIT

sym="${PWD}/sym"

# setup for all tests
cd "$tmp"
mkdir -p home expected-home dotfiles/bash dotfiles/mpv/.config/mpv
touch dotfiles/bash/.bashrc
touch dotfiles/mpv/.config/mpv/mpv.conf

nfailed=0
echo "running tests."

echo -e "\n1: dry-run, no conflicts, link bash"
$sym -t home --dry-run dotfiles/bash &> log
expected="dry-run; the following operations are what would have been executed.
LINK: home/.bashrc -> ../dotfiles/bash/.bashrc"
echo "  assertion 1: expected output"; diff log <(echo "$expected") || nfailed=$((nfailed + 1))


echo -e "\n2: dry-run, conflict with bash"
touch home/.bashrc
$sym -t home --dry-run dotfiles/bash &> log
expected="CONFLICT: home/.bashrc already exists. sym cannot create symlinks if there is an existing file.
dry-run; the following operations are what would have been executed."
echo "  assertion 1: expected output"; diff log <(echo "$expected") || nfailed=$((nfailed + 1))
rm -r home; mkdir home


echo -e "\n3: nonexistent target directory"
$sym -t home/foo dotfiles/bash &> log || true
expected="target directory home/foo is not a directory or does not exist"
echo "  assertion 1: expected output"; diff log <(echo "$expected") || nfailed=$((nfailed + 1))


echo -e "\n4: no conflicts, link all"
cd expected-home
mkdir -p .config/mpv
ln -s ../dotfiles/bash/.bashrc .
cd .config/mpv
ln -s ../../../dotfiles/mpv/.config/mpv/mpv.conf .
cd ../../..
$sym -t home -v dotfiles/bash &> log
$sym -t home -v dotfiles/mpv &>> log
expected="LINK: home/.bashrc -> ../dotfiles/bash/.bashrc
MKDIRS: home/.config/mpv
LINK: home/.config/mpv/mpv.conf -> ../../../dotfiles/mpv/.config/mpv/mpv.conf"
echo "  assertion 1: expected output"; diff log <(echo "$expected") || nfailed=$((nfailed + 1))
echo "  assertion 2: expected result"; diff -r --no-dereference home expected-home || nfailed=$((nfailed + 1))
rm -r home; mkdir home
rm -r expected-home; mkdir expected-home


echo -e "\n5: conflict with mpv (link should be noop)"
mkdir -p home/.config/mpv expected-home/.config/mpv
touch home/.config/mpv/mpv.conf expected-home/.config/mpv/mpv.conf
$sym -t home dotfiles/mpv &> log || true
expected="CONFLICT: home/.config/mpv/mpv.conf already exists. sym cannot create symlinks if there is an existing file.
sym will not start until all conflicts are resolved."
echo "  assertion 1: expected output"; diff log <(echo "$expected") || nfailed=$((nfailed + 1))
echo "  assertion 2: expected result"; diff -r --no-dereference home expected-home || nfailed=$((nfailed + 1))
rm -r home; mkdir home
rm -r expected-home; mkdir expected-home


echo -e "\n6: dry-run, unlink all"
$sym -t home dotfiles/bash > /dev/null
$sym -t home dotfiles/mpv > /dev/null
$sym -t home --delete --dry-run dotfiles/bash &> log
$sym -t home --delete --dry-run dotfiles/mpv &>> log
expected="dry-run; the following operations are what would have been executed.
UNLINK: home/.bashrc
dry-run; the following operations are what would have been executed.
UNLINK: home/.config/mpv/mpv.conf"
echo "  assertion 1: expected output"; diff log <(echo "$expected") || nfailed=$((nfailed + 1))
rm -r home; mkdir home


echo -e "\n7: dry-run, unlink mpv, absolute symlink to same path (resolves correctly, not a conflict)"
$sym -t home dotfiles/mpv > /dev/null
ln -sf "$(readlink -f home/.config/mpv/mpv.conf)" home/.config/mpv/mpv.conf
$sym -t home --delete --dry-run dotfiles/mpv &> log
expected="dry-run; the following operations are what would have been executed.
UNLINK: home/.config/mpv/mpv.conf"
echo "  assertion 1: expected output"; diff log <(echo "$expected") || nfailed=$((nfailed + 1))
rm -r home; mkdir home


echo -e "\n8: unlink only mpv"
$sym -t home dotfiles/bash > /dev/null
$sym -t home dotfiles/mpv > /dev/null
cd expected-home
ln -s ../dotfiles/bash/.bashrc .
cd ..
$sym -t home -v -d dotfiles/mpv &> log
expected="UNLINK: home/.config/mpv/mpv.conf
RMDIR: home/.config/mpv
RMDIR: home/.config"
echo "  assertion 1: expected output"; diff log <(echo "$expected") || nfailed=$((nfailed + 1))
echo "  assertion 2: expected result"; diff -r --no-dereference home expected-home || nfailed=$((nfailed + 1))
rm -r home; mkdir home
rm -r expected-home; mkdir expected-home


echo -e "\n9: try to unlink bash, but conflict; bash is not owned by sym (relative symlink)"
touch foo
cd home
ln -s ../foo .bashrc
cd ../expected-home
ln -s ../foo .bashrc
cd ..
$sym -t home -v -d dotfiles/bash &> log || true
expected="CONFLICT: home/.bashrc does not point to the expected destination, so refusing to remove.
sym will not start until all conflicts are resolved."
echo "  assertion 1: expected output"; diff log <(echo "$expected") || nfailed=$((nfailed + 1))
echo "  assertion 2: expected result"; diff -r --no-dereference home expected-home || nfailed=$((nfailed + 1))
rm -r home; mkdir home
rm -r expected-home; mkdir expected-home


echo -e "\n10: try to unlink all, but conflict; a non-symlink file exists"
mkdir -p home/.config/mpv expected-home/.config/mpv
echo foobar > home/.config/mpv/mpv.conf
echo foobar > expected-home/.config/mpv/mpv.conf
$sym -t home -v dotfiles/mpv &> log || true
expected="CONFLICT: home/.config/mpv/mpv.conf already exists. sym cannot create symlinks if there is an existing file.
sym will not start until all conflicts are resolved."
echo "  assertion 1: expected output"; diff log <(echo "$expected") || nfailed=$((nfailed + 1))
echo "  assertion 2: expected result"; diff -r --no-dereference home expected-home || nfailed=$((nfailed + 1))
rm -r home; mkdir home
rm -r expected-home; mkdir expected-home


echo -e '\ntesting finished.'
(( "$nfailed" > 0 )) && die "failed ${nfailed} assertions"
