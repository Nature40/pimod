# pidiff.sh GitHub Action

Compare two disk images and generate an rsync batch file for incremental updates.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `base_image` | Yes | - | Path to the base image file |
| `updated_image` | Yes | - | Path to the updated image file |
| `partition` | No | `2` | Rootfs partition number |
| `output` | No | Auto-generated | Output batch file path (without extension) |
| `tar` | No | `false` | Create tar archive containing batch and batch.sh files |
| `rsync_options` | No | - | Additional rsync options (space-separated) |

## Usage

### Basic

```yaml
- name: Run PIDIFF
  uses: Nature40/pimod/pidiff@master
  with:
    base_image: base.img
    updated_image: updated.img
```

### With Options

```yaml
- name: Run PIDIFF
  uses: Nature40/pimod/pidiff@master
  with:
    base_image: base.img
    updated_image: updated.img
    output: update-package
    tar: 'true'
    partition: '2'
    rsync_options: '--verbose --exclude="*.pyc" --exclude="/tmp/*"'
```

## Output Files

- **Default**: `{output}.batch` and `{output}.batch.sh`
- **With tar**: `{output}.tar` (contains both files)
- **Auto-named**: `{base}_to_{updated}.batch` if `output` not specified

## Applying Updates

```bash
# Extract (if tar)
tar -xf update-package.tar

# Apply
sudo ./batch.sh /path/to/target/rootfs
```

The batch script includes safety checks: root privileges, target validation, and OS version matching.

## See Also

- [Main pimod README](../README.md)
- [pidiff.sh](../pidiff.sh)
