# Module 01 — Troubleshooting Guide

Problems that actually occurred while setting up the VM, the Telco project and this project, with the diagnosis and the fix that worked.

## First checks

```bash
docker compose ps                         # is the service Up?
docker compose logs --tail 50 chat-agent  # what does it say?
./homework/module-01/submission/test_services.sh   # exit code 0 = healthy
```

## Project (ecommerce-start)

### `make start` / `init_project.sh` start nothing

- **Symptom:** `docker-compose -f docker/docker-compose.yml up -d` fails with `empty compose file`; `init_project.sh` stops at the build step.
- **Cause:** `docker/docker-compose.yml` is an empty placeholder (0 bytes). The working Compose file is in the repository root.
- **Fix:** run Compose from the root: `docker compose up -d --build`.

### UI shows "No data found. Run the data generator.!"

- **Cause:** `data/products.csv` does not exist. The README points to `scripts/generate_data.py`, which is not in the repository.
- **Fix:** use the real generator, inside the container so no local Python setup is needed:

  ```bash
  docker compose run --rm --user $(id -u):$(id -g) chat-agent \
    python scripts/data/generate_ecommerce_data.py
  ```

  `--user` keeps the generated files owned by you instead of `root`. Reload the browser page afterwards; if the warning stays, restart the service to clear the cache: `docker compose restart chat-agent`.

### `scripts/module-01/verify_setup.py` reports every service as down

- **Cause:** it checks ports 8001–8003, 5000, 3000 and 9090, which belong to services added in later modules.
- **Fix:** for Module 01 use `test_services.sh`, which checks the one service that exists (8501).

### UI does not open from the host browser

- **Diagnosis:** `curl -I localhost:8501` works inside the VM but not on the host.
- **Cause:** port 8501 is not forwarded by the Vagrantfile.
- **Fix:** add `config.vm.network "forwarded_port", guest: 8501, host: 8501` and run `vagrant reload`. To avoid a restart, add the rule to the running VM:

  ```bash
  VBoxManage controlvm "$(cat .vagrant/machines/default/virtualbox/id)" natpf1 "streamlit,tcp,,8501,,8501"
  ```

### Port already in use

- **Diagnosis:** `ss -ltnp | grep 8501` (in the VM and on the host).
- **Fix:** stop the other process, or change the left side of `ports:` in `docker-compose.yml` and the forwarded host port.

## VM and Docker

### `make install` fails with `python: command not found`

- **Cause:** Ubuntu 22.04 ships only `python3`; the Telco Makefile calls `python`.
- **Fix:** `sudo apt-get install -y python-is-python3` (now part of the Vagrant provisioning).

### VM disk is 31 GB although 60 GB was requested

- **Diagnosis:** `df -h /` shows 31G; `lsblk` shows a 64G disk.
- **Cause:** the `vagrant-disksize` plugin grows the virtual disk, but the bento box uses LVM and the logical volume is not extended automatically.
- **Fix:** `sudo lvextend -r -l +100%FREE /dev/ubuntu-vg/ubuntu-lv` (now part of the provisioning).

### Provisioning script breaks on the course Vagrantfile

- **Cause:** the course Vagrantfile has Windows line endings (CRLF); the trailing `\r` ends up inside the inline shell script.
- **Fix:** convert it: `sed -i 's/\r$//' Vagrantfile`.

### `config.vm.disk` has no effect

- **Cause:** it needs `VAGRANT_EXPERIMENTAL="disks"`.
- **Fix:** use the plugin instead: `vagrant plugin install vagrant-disksize` and `config.disksize.size = "60GB"`.

### `pip install` fails in the provisioned venv with a permission error

- **Cause:** provisioning runs as root, so the venv belongs to root.
- **Fix:** `sudo chown -R vagrant:vagrant ~/mlops-venv` (now part of the provisioning).

### VM becomes `inaccessible` after the laptop sleeps

- **Symptom:** the VM lived on an external Thunderbolt NVMe; after suspend/resume the disk disconnected, ext4 reported I/O errors and VirtualBox lost the VM files.
- **Fix:** reconnect or reboot, let the journal recover (`fsck.ext4 -f` if needed), mount the disk, `vagrant up`. If the VM disk were damaged, `vagrant destroy -f && vagrant up` rebuilds the whole environment from the Vagrantfile.
- **Prevention:** `vagrant halt` (or `vagrant suspend`) before closing the lid.

### `docker` needs sudo

- **Cause:** the user is not in the `docker` group, or the session started before it was added.
- **Fix:** `sudo usermod -aG docker $USER`, then log out and back in (`exit`, `vagrant ssh`).

## Git and GitHub

### `git push` returns 403 `Permission denied`

- **Cause:** the fine-grained personal access token had `Contents` and `Pull requests` set to read-only. Creating repositories worked, pushing did not.
- **Fix:** GitHub → Settings → Developer settings → Fine-grained tokens → the token → Edit → set **Contents** and **Pull requests** to *Read and write* → **Update**. No new token or re-login is needed.

### JupyterLab asks for a token (Telco project)

- **Fix:** the token is set in `docker-compose.yml` (`JUPYTER_TOKEN`); open `http://localhost:8888/lab?token=<value>`, or read it from `docker compose logs jupyter`.
