{ callPackage, runCommand, writeShellScriptBin, stdenv, coreutils, bubblewrap }:

let buildFHSEnv = callPackage ./env.nix { }; in

args @ {
  name,
  runScript ? "bash",
  extraInstallCommands ? "",
  meta ? {},
  passthru ? {},
  bwrap_args ? "",
  automount ? true,
  chdir ? "$(pwd)",
  ...
}:

with builtins;
let
  env = buildFHSEnv (removeAttrs args [
    "runScript" "extraInstallCommands" "meta" "passthru"
    "bwrap_args" "automount" "chdir"
  ]);

  chrootenv = callPackage ./chrootenv {};

  init = run: writeShellScriptBin "${name}-init" ''
    for i in ${env}/* /host/*; do
      path="/''${i##*/}"
      [ -e "$path" ] || ${coreutils}/bin/ln -s "$i" "$path"
    done

    source /etc/profile
    exec ${run} "$@"
  '';

  mounts = attrNames (readDir "${env}");
  ro_mounts = map (m: "--ro-bind ${env}/${m} ${m}") mounts;
  blacklist = map (m: "/${m}") (mounts ++ ["nix" "dev" "proc"]);

  find_automounts = ''
    blacklist="${concatStringsSep " " blacklist}"
    auto_mounts=""
    # loop through all directories in the root
    for dir in /*; do
      # if it is a directory and it is not in the blacklist
      if [[ -d "$dir" ]] && grep -v "$dir" <<< "$blacklist" >/dev/null; then
        # add it to the mount list
        auto_mounts="$auto_mounts --bind $dir $dir"
      fi
    done
  '';

  bwrap_cmd = { init_args ? "" }: ''
    ${if automount then find_automounts else ""}

    exec ${bubblewrap}/bin/bwrap \
      --chdir ${chdir} \
      --dev /dev \
      --proc /proc \
      --unshare-all \
      --share-net \
      --die-with-parent \
      --ro-bind /nix /nix \
      --ro-bind /etc /host/etc \
      ${concatStringsSep " " ro_mounts} \
      ${if automount then "$auto_mounts" else ""} \
      ${bwrap_args} \
      ${init runScript}/bin/${name}-init ${init_args}
  '';

  bin = writeShellScriptBin name (bwrap_cmd { init_args = ''"$@"''; });

in runCommand name {
  inherit meta;
  passthru = passthru // {
    env = runCommand "${name}-shell-env" {
      shellHook = bwrap_cmd {};
    } ''
      echo >&2 ""
      echo >&2 "*** User chroot 'env' attributes are intended for interactive nix-shell sessions, not for building! ***"
      echo >&2 ""
      exit 1
    '';
  };
} ''
  mkdir -p $out/bin
  ln -s ${bin}/bin/${name} $out/bin/${name}
  ${extraInstallCommands}
''
