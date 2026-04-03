# `phase_correlation.m` — Version-consistent image registration for fUSI

## Overview

`phase_correlation.m` is a drop-in replacement for MATLAB's built-in
`imregcorr(..., 'translation')` function. It estimates the translational
shift between two images using the **normalised cross-power spectrum**
(also known as *phase correlation*), and returns a `transltform2d` object
that is fully compatible with `imwarp`, `tform.Translation`, and `tform.T`.

```matlab
% Usage (identical to imregcorr):
tform = phase_correlation(moving, fixed);
```

---

## Why not just use `imregcorr`?

### The problem: different results across MATLAB versions

MATLAB's `imregcorr` produces **different results** for identical inputs
depending on the version:

| Version | Default algorithm | Observed result |
|---|---|---|
| R2022b (9.13) | `phasecorr` | `Translation: [0, 0]` for small shifts |
| R2025a (25.1) | `gradcorr` (new default) | `Translation: [0.0038, -0.0354]` (correct) |

There are **two independent changes** between R2022b and R2025a:

#### 1. The default algorithm changed

In R2022b, `imregcorr` always uses phase correlation (`phasecorr`).
In R2025a, MathWorks changed the default to **Normalized Gradient Correlation**
(`gradcorr`) — a completely different method that operates on image gradients
rather than on the Fourier spectrum. You can verify this by looking at the
parser line in R2025a's source:

```matlab
% R2025a only:
parser.addParameter('method', 'gradcorr', @validateMethod)
%                              ^^^^^^^^^^ new default
```

This parameter does not exist at all in R2022b.

#### 2. The internal peak-detection function changed behaviour

In both versions, the `phasecorr` path delegates peak-finding to a compiled
internal function called `findTranslationPhaseCorr`. This function is not
exposed in the source — it is a pre-compiled MEX/p-code routine.
In R2022b, this compiled function contains an internal confidence threshold:
when the peak of the correlation map is deemed too weak (e.g. because the
true shift is very small, producing a flat, low-amplitude peak), it silently
returns `[0, 0]` instead of the actual best estimate.

The public 0.03 threshold visible in the R2022b source code only issues a
*warning* and does not cause `[0, 0]` — so the silent zero must originate
inside the compiled function itself.

> **Bottom line:** the formula is the same in both versions, but the compiled
> black-box function that evaluates the result behaves differently.

### The solution: implement every step in transparent MATLAB code

`phase_correlation.m` reimplements the entire pipeline explicitly —
FFT, normalised cross-power spectrum, peak detection, and sub-pixel
refinement — without relying on any compiled internal function. This
gives **identical results on all MATLAB versions** (verified on R2022b
and R2025a).

---

## Algorithm

The function follows the standard phase-correlation pipeline:

### Step 1 — Hann windowing

Both images are multiplied by a separable 2-D Hann window before the FFT.
This fades the image edges smoothly to zero, suppressing the artificial
high-frequency components that would otherwise arise from the hard borders
(the FFT implicitly assumes the image tiles periodically).

```matlab
win = hann(rows) * hann(cols)';
```

> Note: MathWorks uses a Blackman window internally, which has slightly
> better side-lobe suppression (−58 dB vs −31 dB). For fUSI motion
> correction the difference is negligible.

### Step 2 — Normalised cross-power spectrum

The core of phase correlation. Instead of computing a standard
cross-correlation (slow, O(N²)), we work in the Fourier domain where a
spatial shift appears as a phase difference between the two spectra:

```
R(u,v) = FFT(fixed) × conj(FFT(moving))
         ─────────────────────────────────
         | FFT(fixed) × conj(FFT(moving)) |
```

Dividing by the magnitude retains **only the phase information**, making
the result insensitive to differences in image brightness or contrast
between frames.

### Step 3 — Inverse FFT → correlation map

```matlab
r = real(ifft2(R));
```

The resulting map has a **sharp peak at the position corresponding to the
translation** between the two images. This is equivalent to sliding one
image over the other and measuring the match at every possible offset —
but computed in a single FFT operation.

### Step 4 — Sub-pixel refinement (parabolic fit)

The integer peak position gives the translation to the nearest pixel.
To recover sub-pixel accuracy, a parabola is fitted through the three
points surrounding the peak along each axis:

```
         ●   ← true sub-pixel peak (from parabola)
       ● ● ● ← three measured correlation values
```

**This step is the key difference from R2022b's compiled function**, which
apparently abandoned the sub-pixel estimate when the peak amplitude was
below an internal threshold, returning `[0, 0]` instead.

### Step 5 — Sign convention (wrap-around)

Because the IFFT is cyclic, a shift of *k* pixels to the right looks the
same as a shift of *(N − k)* pixels to the left. Shifts greater than half
the image width are converted to their negative equivalent.

---

## Suitability for fUSI image registration

Phase correlation for translation-only motion correction is
**the standard and well-validated approach** for this type of data.
It is used routinely in:

- **fMRI motion correction** (SPM's realignment step uses the same
  normalised cross-power spectrum)
- **Functional ultrasound imaging** (fUSI), where in-plane head movements
  need to be corrected before connectivity or activation analysis
- **Medical ultrasound** in general (e.g. cardiac wall motion estimation)
- **Remote sensing** (satellite image alignment)
- **Video stabilisation** and microscopy time-series

### Why it is particularly well-suited to fUSI

| Requirement | fUSI situation |
|---|---|
| **Same imaging modality** | ✅ All frames are PDI (Power Doppler Images) from the same transducer |
| **Stable contrast** | ✅ No modality change between frames |
| **Small translations only** | ✅ Head is fixed; only small rigid shifts expected |
| **Rich spatial frequency content** | ✅ Cerebrovascular architecture provides strong texture across all scales |
| **Speed** | ✅ FFT-based; O(N log N), fast even for hundreds of frames |

### Limitations to be aware of

- **Translation only**: phase correlation detects shifts but not rotation or
  scaling. This is appropriate for fUSI with a fixed head (and is already
  the assumption in the original `imregcorr` call).
- **Large shifts**: shifts larger than half the image size are ambiguous.
  Not a concern for small physiological head motion.
- **Different modalities**: if comparing images from different scanners or
  contrasts, mutual-information-based registration would be needed. Not
  applicable here.

---

## References

- Kuglin, C.D. & Hines, D.C. (1975). *The phase correlation image alignment
  method.* Proc. IEEE International Conference on Cybernetics and Society,
  pp. 163–165. — **Original paper introducing phase correlation.**

- Reddy, B.S. & Chatterji, B.N. (1996). *An FFT-based technique for
  translation, rotation, and scale-invariant image registration.* IEEE
  Transactions on Image Processing, 5(8), 1266–1271.
  — **Used as the reference by MathWorks for `imregcorr`.**

- Stone, H.S., Tao, B. & McGuire, M. (2001). *Analysis of image registration
  noise due to rotationally dependent aliasing.* Journal of Visual
  Communication and Image Representation.
  — **Motivates the Blackman/Hann windowing step.**

- Friston, K.J. et al. (1995). *Spatial registration and normalisation of
  images.* Human Brain Mapping, 3, 165–189.
  — **SPM's motion correction, which uses the same phase-correlation
  approach for fMRI — the direct neuroimaging precedent for fUSI.**
